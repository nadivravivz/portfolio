module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets

  tags = {
    Environment = "training"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id


  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "Raviv Portfolio"
      asg_desired_capacity          = 3
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t2.small"
      additional_userdata           = "Raviv Portfolio"
      asg_desired_capacity          = 3
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
    {
      name                          = "worker-group-3"
      instance_type                 = "t2.small"
      additional_userdata           = "Raviv Portfolio"
      asg_desired_capacity          = 3
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "null_resource" "logging" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name Raviv-PortfolioEKS --region eu-central-1"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [module.eks]
}

resource "helm_release" "kibana" {
  name       = "kibana"
  repository = "https://helm.elastic.co"
  chart      = "kibana"
  namespace = "kube-logging"
  depends_on = [helm_release.fluentd]
  create_namespace = true
  values = [<<EOF
  replicas: 1
  resources:
  requests:
    cpu: "400m"
    memory: "0.5Gi"
  limits:
    cpu: "500m"
    memory: "1.0Gi"
  EOF
  ]
}

resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  namespace = "kube-logging"
  create_namespace = true
  values = [<<EOF
  replicas: 1
  minimumMasterNodes: 1
  resources:
  requests:
    cpu: "500m"
    memory: "1.0Gi"
  limits:
    cpu: "500m"
    memory: "1.0Gi"
  EOF
  ]
}

resource "helm_release" "fluentd" {
  name       = "fluentd"  
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluentd"
  namespace = "kube-logging"
  depends_on = [helm_release.elasticsearch]
  create_namespace = true  
  values = [<<EOF
  fileConfigs:
    01_sources.conf: |-
      <source>
        @id fluentd-containers.log
        @type tail
        path /var/log/containers/*.log
        pos_file /var/log/containers.log.pos
        tag raw.kubernetes.*
        read_from_head true
        <parse>
          @type multi_format
          <pattern>
            format json
            time_key time
            time_format %Y-%m-%dT%H:%M:%S.%NZ
          </pattern>
          <pattern>
            format /^(?<time>.+) (?<stream>stdout|stderr) [^ ]* (?<log>.*)$/
            time_format %Y-%m-%dT%H:%M:%S.%N%:z
          </pattern>
        </parse>
      </source>

    02_filters.conf: |-
      # Detect exceptions in the log output and forward them as one log entry.
      <match raw.kubernetes.**>
        @id raw.kubernetes
        @type detect_exceptions
        remove_tag_prefix raw
        message log
        stream stream
        multiline_flush_interval 5
        max_bytes 500000
        max_lines 1000
      </match>

      # Concatenate multi-line logs
      <filter **>
        @id filter_concat
        @type concat
        key message
        multiline_end_regexp /\n$/
        separator ""
        timeout_label @NORMAL
        flush_interval 5
      </filter>

      # Enriches records with Kubernetes metadata
      <filter kubernetes.**>
        @id filter_kubernetes_metadata
        @type kubernetes_metadata
      </filter>

      # Fixes json fields in Elasticsearch
      <filter kubernetes.**>
        @id filter_parser
        @type parser
        key_name log
        reserve_time true
        reserve_data true
        remove_key_name_field true
        <parse>
          @type multi_format
          <pattern>
            format json
          </pattern>
          <pattern>
            format none
          </pattern>
        </parse>
      </filter>

    03_dispatch.conf: |-

    04_outputs.conf: |-
      # handle timeout log lines from concat plugin
      <match **>
        @type relabel
        @label @NORMAL
      </match>

      <label @NORMAL>
      <match **>
        @id elasticsearch
        @type elasticsearch
        @log_level info
        include_tag_key true
        host "elasticsearch-master"
        port 9200
        path ""
        scheme http
        ssl_verify true
        ssl_version TLSv1_2
        type_name _doc
        logstash_format true
        logstash_prefix logstash
        reconnect_on_error true
        <buffer>
          @type file
          path /var/log/fluentd-buffers/kubernetes.system.buffer
          flush_mode interval
          retry_type exponential_backoff
          flush_thread_count 2
          flush_interval 5s
          retry_forever
          retry_max_interval 30
          chunk_limit_size 2M
          queue_limit_length 8
          overflow_action block
        </buffer>
      </match>
      </label>  
    EOF
    ]
  }


resource "helm_release" "kube-prometheus-stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace = "kube-prometheus"
  depends_on = [helm_release.kibana]
  create_namespace = true
  values = [<<EOF
  resources:
  requests:
    cpu: "500m"
    memory: "1.0Gi"
  limits:
    cpu: "500m"
    memory: "1.0Gi"
  EOF
  ]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace = "default"
  depends_on = [helm_release.kube-prometheus-stack]
  values = [<<EOF
  EOF
  ]
}

resource "helm_release" "portfolio" {
  name       = "portfolio"
  chart      = "./portfoliochart"
  namespace = "default"
  depends_on = [helm_release.argocd]
  values = [<<EOF
  EOF
  ]
}

resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace = "default"
  depends_on = [helm_release.portfolio]
  values = [<<EOF
  EOF
  ]
}


resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace = "default"
  depends_on = [helm_release.ingress-nginx]
  values = [<<EOF
  EOF
  ]
}