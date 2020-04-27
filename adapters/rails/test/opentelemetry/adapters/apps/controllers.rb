require 'action_view/testing/resolvers'

# ActionText requires an ApplicationController to be defined since Rails 6
class ApplicationController < ActionController::Base; end

class TracingController < ActionController::Base
  include Rails.application.routes.url_helpers

  layout 'application'

  self.view_paths = [
    ActionView::FixtureResolver.new(
      'layouts/application.html.erb' => '<%= yield %>',
      'views/tracing/index.html.erb' => 'Hello from index.html.erb',
      'views/tracing/partial.html.erb' => 'Hello from <%= render "views/tracing/body.html.erb" %>',
      'views/tracing/full.html.erb' => '<% Article.all.each do |article| %><% end %>',
      'views/tracing/error.html.erb' => '<%= 1/0 %>',
      'views/tracing/missing_partial.html.erb' => '<%= render "ouch.html.erb" %>',
      'views/tracing/sub_error.html.erb' => '<%= 1/0 %>',
      'views/tracing/soft_error.html.erb' => 'nothing',
      'views/tracing/not_found.html.erb' => 'nothing',
      'views/tracing/error_partial.html.erb' => 'Hello from <%= render "views/tracing/inner_error.html.erb" %>',
      'views/tracing/nested_partial.html.erb' => 'Server says (<%= render "views/tracing/outer_partial.html.erb" %>)',
      'views/tracing/_outer_partial.html.erb' => 'Outer partial: (<%= render "views/tracing/inner_partial.html.erb" %>)',
      'views/tracing/_inner_partial.html.erb' => 'Inner partial',
      'views/tracing/_body.html.erb' => '_body.html.erb partial',
      'views/tracing/_inner_error.html.erb' => '<%= 1/0 %>'
    )
  ]

  def index
    render 'views/tracing/index.html.erb'
  end

  def partial
    render 'views/tracing/partial.html.erb'
  end

  def nested_partial
    render 'views/tracing/nested_partial.html.erb'
  end

  def error
    1 / 0
  end

  def soft_error
    if Rails::VERSION::MAJOR.to_i >= 5
      head 520
    else
      render nothing: true, status: 520
    end
  end

  def sub_error
    a_nested_error_call
  end

  def a_nested_error_call
    another_nested_error_call
  end

  def another_nested_error_call
    error
  end

  def not_found
    # Here we raise manually a 'Not Found' exception.
    # The conversion is by default done by Rack::Utils.status_code using
    # http://www.rubydoc.info/gems/rack/Rack/Utils#HTTP_STATUS_CODES-constant
    raise ActionController::RoutingError, :not_found
  end

  def error_template
    render 'views/tracing/error.html.erb'
  end

  def missing_template
    render 'views/tracing/ouch.not.here'
  end

  def missing_partial
    render 'views/tracing/missing_partial.html.erb'
  end

  def error_partial
    render 'views/tracing/error_partial.html.erb'
  end

  def full
    render 'views/tracing/full.html.erb'
  end
end
