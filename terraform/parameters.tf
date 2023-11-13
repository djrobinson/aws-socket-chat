	
# parameters.tf
resource "aws_ssm_parameter" "endpoint" {
  name        = "/database/${var.name}/endpoint"
  description = "Endpoint to connect to the ${var.name} database"
  type        = "SecureString"
  value       = "${module.db.db_instance_address}"
}