output "account_id" {
    value = data.aws_caller_identity.test_call_id.account_id
}
output "caller_user" {
    value = data.aws_caller_identity.test_call_id.user_id
}
output "aws_reg" {
    value = data.aws_region.test_reg.description
}
output "Private_ip_addr" {
    value = aws_instance.test.private_ip
}
#output "test" {
#  value      = data.aws_subnet_ids.selected.*.isd
#}

