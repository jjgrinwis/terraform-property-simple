# This module is oing to be used via Terraform Cloud, so make sure to set credentials in TF cloud.
# https://techdocs.akamai.com/terraform/docs/environment-variables


# look all all contractual information
data "akamai_contract" "contract" {
  group_name = var.group_name
}

locals {
  # convert the list of maps to a map of maps with entry.hostname as key of the map
  # this map of maps will be fed into our EdgeDNS module to create the CNAME records.
  dv_records = { for entry in resource.akamai_property.aka_property.hostnames[*].cert_status[0] : entry.hostname => entry }

  cp_code_id = tonumber(trimprefix(resource.akamai_cp_code.cp_code.id, "cpc_"))
}

# for the demo don't create cpcode's over and over again, just reuse existing one
# if cpcode already existst it will take the existing one.
# For this demo hard coding some vars.
resource "akamai_cp_code" "cp_code" {
  name        = "jgrinwis"
  contract_id = data.akamai_contract.contract.id
  group_id    = data.akamai_contract.contract.group_id
  product_id  = "prd_Fresca"
}

resource "akamai_property" "aka_property" {
  name        = var.hostname
  contract_id = data.akamai_contract.contract.id
  group_id    = data.akamai_contract.contract.group_id
  product_id  = resource.akamai_cp_code.cp_code.product_id
  rule_format = "latest"


  # our pretty static hostname configuration so a simple 1:1 between front-end and back-end
  hostnames {
    cname_from = var.hostname
    cname_to   =  "${var.hostname}.edgesuite.net"
    cert_provisioning_type = "DEFAULT"
  }

  # our pretty static rules file. Only dynamic part is the origin name
  # we could use the akamai_template but trying standard templatefile() for a change.
  # we might want to add cpcode in here which is statically configured now
  rules = templatefile(".terraform/modules/simple/akamai_config/config.tftpl", { origin_hostname = var.origin_hostname, cp_code_id = local.cp_code_id, cp_code_name = "jgrinwis" })
}

resource "akamai_property_activation" "aka_staging" {
  property_id = resource.akamai_property.aka_property.id
  contact     = ["jgrinwis@akamai.com"]
  version     = resource.akamai_property.aka_property.latest_version
  network     = "STAGING"
  note        = "Action triggered by Terraform."
  auto_acknowledge_rule_warnings = true
}