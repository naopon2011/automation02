
terraform {
  required_providers {
    zpa = {
      source = "zscaler/zpa"
      version = "~> 3.0.0"
    }
  }
}
provider "zpa" {
  zpa_client_id         =  "MjE2MTk5NjIxMzY0NDE2OTEzLWU1M2ExZTAyLTZiMzgtNDE3ZC1hMzY1LWM5YjZkN2UxNGI4Ng=="
  zpa_client_secret     =  "5X:/3WkjKAO?]<4T%!]`iD!9*SG.GkNl"
  zpa_customer_id       =  "216199621364416512"
}

// Create Application Segment
resource "zpa_application_segment" "crm_application" {
  name             = "CRM Application"
  description      = "CRM Application"
  enabled          = true
  health_reporting = "ON_ACCESS"
  bypass_type      = "NEVER"
  is_cname_enabled = true
  tcp_port_ranges  = ["80", "80"]
  domain_names     = [${aws_instance.app_connector.private_dns}]
  segment_group_id = zpa_segment_group.crm_app_group.id
  server_groups {
    id = [zpa_server_group.crm_servers.id]
  }
}

// Create Server Group
resource "zpa_server_group" "crm_servers" {
  name              = "CRM Servers"
  description       = "CRM Servers"
  enabled           = true
  dynamic_discovery = false
  app_connector_groups {
    id = [data.zpa_app_connector_group.dc_connector_group.id]
  }
  servers {
    id = [zpa_application_server.crm_app_server.id]
  }
}

// Create Application Server
resource "zpa_application_server" "crm_app_server" {
  name        = "CRM App Server"
  description = "CRM App Server"
  address     = "crm.example.com"
  enabled     = true
}

// Create Segment Group
resource "zpa_segment_group" "crm_app_group" {
  name            = "CRM App group"
  description     = "CRM App group"
  enabled         = true
  policy_migrated = true
}

// Retrieve App Connector Group
data "zpa_app_connector_group" "dc_connector_group" {
  name = "test"
}

