output "kong_url" {
  description = "URL pública do Kong Gateway"
  value       = "http://${aws_eip.oficina.public_ip}:8000"
}

output "public_ip" {
  description = "IP público (Elastic IP - persiste após destroy)"
  value       = aws_eip.oficina.public_ip
}

output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.oficina.id
}

output "next_steps" {
  description = "Próximos passos"
  value       = <<-EOT
    ✅ Infraestrutura criada com sucesso!

    Kong Gateway: http://${aws_eip.oficina.public_ip}:8000

    Teste:
    curl http://${aws_eip.oficina.public_ip}:8000/health

    ⚠️ Aguarde ~3 minutos para containers iniciarem
  EOT
}
