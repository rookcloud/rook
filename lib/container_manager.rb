module Rook
  class ContainerManager
    def initialize(config, component, container)
      @config    = config
      @component = component
      @container = container
    end

    def install
      params = [
        "-n", state.namespace,
        "-t", @component.type
      ]
      if @config.development_mode?
        params << "-e"
      end
      if @component.app_server?
        params << "-a"
        if @config.development_mode?
          params << "-p"
          if using_vagrant?
            params << "/vagrant"
          else
            params << @config.app_path
          end
        else
          payload << app_tarball
        end
      end

      docker_options = []
      tunnels = []
      @container.service_port_redirections.each_pair do |service_port, host_port|
        docker_options << "-p 0.0.0.0:#{host_port}:#{service_port}"
      end
      @container.routes.each do |route|
        docker_options << "-e #{route.environment_name}=#{route.source_port}"
        tunnels << [route.source_port,
          route.destination.host.address,
          route.destination.host.ssh_port,
          route.destination.service_port_redirections[route.service_port]
        ].join(" ")
      end
      include docker_options and tunnels in config_tarball

      payload << config_tarball

      run_script("install.sh", params, payload)
    end

    def uninstall
      params = [
        "-n", state.namespace,
        "-t", @component.type
      ]
      run_script("uninstall.sh", params)
    end

    def start
      params = [
        "-n", state.namespace,
        "-t", @component.type
      ]
      if @component.app_server?
        params << "-a"
      end
      run_script("start.sh", params)
    end

    def stop
      params = [
        "-n", state.namespace,
        "-t", @component.type
      ]
      run_script("stop.sh", params)
    end
  end
end
