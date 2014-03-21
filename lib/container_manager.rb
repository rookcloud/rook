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
