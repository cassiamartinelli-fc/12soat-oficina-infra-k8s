output "kong_url" {
  description = "URL pública do Kong Gateway"
  value       = "http://${aws_instance.oficina.public_ip}:30080"
}

output "public_ip" {
  description = "IP público da EC2"
  value       = aws_instance.oficina.public_ip
}

output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.oficina.id
}

output "next_steps" {
  description = "Próximos passos"
  value       = <<-EOT
    ✅ Infraestrutura criada com sucesso!

    Kong Gateway: http://${aws_instance.oficina.public_ip}:30080

    Teste:
    curl http://${aws_instance.oficina.public_ip}:30080/os-service/health

    ⚠️ Aguarde ~3 minutos para K3s e Kong iniciarem
  EOT
}
