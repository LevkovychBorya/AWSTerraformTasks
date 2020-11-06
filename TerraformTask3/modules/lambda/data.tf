data "archive_file" "function" {
  type        = "zip"
  source_file = var.function_file_path
  output_path = format("%s.zip", split(".", var.function_file_path)[0])
}