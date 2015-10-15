# -*- mode: ruby -*-
# vi: set ft=ruby :

##
# overwrite: VagrantPlugins::ProviderLibvir::Util::ErbTemplate::to_xml().
# vagrant-libvirt-0.0.25(-0.0.30) is unsupported customizing detailed CPU.
#
# ~/.vagrant.d/gems/gems/vagrant-libvirt-x.x.xx/lib/vagrant-libvirt/util/erb_template.rb
# ~/.vagrant.d/gems/gems/vagrant-libvirt-x.x.xx/lib/vagrant-libvirt/templates/domain.xml.erb
##

require 'vagrant-libvirt/util/erb_template'
require 'erubis'

module VagrantPlugins
  module ProviderLibvirt
    module Util
      module ErbTemplate
        def to_xml_new template_name = nil, data = binding
          erb = template_name || self.class.to_s.split("::").last.downcase
          if erb == "domain"
            path = File.join(File.dirname(__FILE__), "templates", "#{erb}.xml.erb")
            puts "overwrite templates! path: #{path}"
            template = File.read(path)
            Erubis::Eruby.new(template, :trim => true).result(data)
          else
            to_xml_ori(template_name, data)
          end
        end

        alias_method :to_xml_ori, :to_xml
        alias_method :to_xml, :to_xml_new
      end
    end
  end
end
