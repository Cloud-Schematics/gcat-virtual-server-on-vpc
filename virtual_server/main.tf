##############################################################################
# Virtual Server Data
##############################################################################

data ibm_is_image image {
    name = var.image
}

locals {

    # Create list of VSI using subnets and VSI per subnet
    vsi_list = flatten([
        # For each subnet
        for subnet in var.subnets: [
            # For each number in a range from 0 to VSI per subnet
            for count in range(var.vsi_per_subnet):
            {
                name      = "${subnet.name}-${var.prefix}-${count + 1}"
                subnet_id = subnet.id
                zone      = subnet.zone
            }
        ]
    ])

    # Create map of VSI from list
    vsi_map = {
        for server in local.vsi_list:
        server.name => server
    }

}

##############################################################################


##############################################################################
# Create Virtual Servers
##############################################################################

resource ibm_is_instance vsi {
    for_each       = local.vsi_map
    name           = each.key
    image          = data.ibm_is_image.image.id
    profile        = var.machine_type
    resource_group = var.resource_group_id
    vpc            = var.vpc_id
    zone           = each.value.zone
    user_data      = var.user_data
    keys           = [ var.ssh_key_id ]

    primary_network_interface {
        subnet          = each.value.subnet_id
        security_groups = [ ibm_is_security_group.vsi_security_group.id ]
    }  
}

##############################################################################