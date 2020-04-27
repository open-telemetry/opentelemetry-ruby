routes = {
  '/' => 'tracing#index',
  '/nested_partial' => 'tracing#nested_partial',
  '/partial' => 'tracing#partial',
  '/full' => 'tracing#full',
  '/error' => 'tracing#error',
  '/soft_error' => 'tracing#soft_error',
  '/sub_error' => 'tracing#sub_error',
  '/not_found' => 'tracing#not_found',
  '/error_template' => 'tracing#error_template',
  '/error_partial' => 'tracing#error_partial',
  '/missing_template' => 'tracing#missing_template',
  '/missing_partial' => 'tracing#missing_partial',
  '/custom_resource' => 'tracing#custom_resource',
  '/custom_tag' => 'tracing#custom_tag',
  '/internal_server_error' => 'errors#internal_server_error'
}

Rails.application.routes.draw do
  routes.each do |k, v|
    get k, to: v
  end
end
