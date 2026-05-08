# prod

name_suffix            = "prod-stack"
aws_account_id         = "123456789012"
devops_agent_role_name = "DevOpsAgentRole-AgentSpace"
domain                 = "octavianpopov.com"
env_subdomain          = ""
acme_email             = "ops@octavianpopov.com"
allowed_cidrs = [
  # "203.0.113.10/32",  # office
  # "198.51.100.42/32", # VPN endpoint
]
