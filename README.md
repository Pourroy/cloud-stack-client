# CloudstackClient

This gem was builded to access Apache CloudStack APIs in a Rails style. Configurate your app to use the APIs and manage your resources from any Cloud Stack environment.

## Installation

```ruby
gem 'cloudstack-client'
```

## Usage

```ruby
    # Create de instance connection with your CloudStack server
    cs = CloudstackClient::Client.new(
        'tracing_variable',
        'url_cloudstack',
        'apikey_cloudstack',
        'secretkey_cloudstack',
        OpenTelemetry::Span::Context # Optional telemetry instance
    )

    # This API attach and iso in your cloudstack virtual machine with the following params
    cs.attach_iso(id: 'image_id', virtualmachineid: 'vm_id') # Always use APIs in snakecase
    # Original API documentation https://cloudstack.apache.org/api/apidocs-4.18/apis/attachIso.html
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Pourroy/cloudstack-client.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
