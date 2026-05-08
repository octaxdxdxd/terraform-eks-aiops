variable "chart" {
  description = "Chart name"
  type        = string
}

variable "name" {
  description = "Helm release name"
  type        = string
}

variable "repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = null
  nullable    = true
}

variable "chart_version" {
  description = "Chart version to install"
  type        = string
  default     = null
  nullable    = true
}

variable "namespace" {
  description = "Kubernetes namespace for the release"
  type        = string
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
}

variable "sets" {
  description = "List of name/value pairs for set"
  type = list(object({
    name  = string
    value = string
    type  = optional(string)
  }))
}

variable "wait" {
  type    = bool
  default = true
}

variable "wait_for_jobs" {
  type    = bool
  default = false
}

variable "timeout" {
  type        = number
  default     = null
  nullable    = true
  description = "Time in seconds to wait for Helm release operations"
}

variable "force_update" {
  type    = bool
  default = false
}

variable "dependency_update" {
  type    = bool
  default = false
}
