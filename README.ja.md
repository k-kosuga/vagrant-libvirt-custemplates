Vagrant + vagrant-libvirt で template をカスタマイズする
======================================

ツール概要
---------------------------
vagrant-libvirt (https://github.com/pradels/vagrant-libvirt) では、
ある程度、Vagrantfile 内で パラメータを変更することで、
生成される libvirt の XML を変更することができる。

しかし、
template も基に XML が生成されているため、
細かな設定ができない。

そこで、
環境にあまり影響しないように(Vagrantfile だけで完結できるように)、
ツール(という程でもないが)を作ってみた。
\# KVM 上で Intel DPDK (http://dpdk.org/) を動かすために、
\# CPU の細かな設定をする必要があったため。

環境
---------------------------
下記の環境で検証済み。

* Ubuntu 14.04
* Vagrant 1.7.2
* Vagrant plugin
    - vagrant-libvirt 0.0.25
    - vagrant-mutate 0.3.2

使い方
---------------------------
### Vagrant 環境構築
1. KVM インストール

        % sudo apt-get install -y \
            qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils \
            libxslt-dev libxml2-dev libvirt-dev dpkg

2. Vagrant インストール

   最新版を入れても問題ない。

        % wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb
        % sudo dpkg -i vagrant_1.7.2_x86_64.deb

3. Vagrant plugin インストール

   最新版を入れても問題ない。

        % vagrant plugin install vagrant-libvirt --plugin-version 0.0.25

        # Virtualbox の 仮想イメージを変換する plugin
        % vagrant plugin install vagrant-mutate --plugin-version 0.3.2

4. 適当な box を落として入れる

        % vagrant box add host01 https://github.com/kraksoft/vagrant-box-ubuntu/releases/download/14.04/ubuntu-14.04-amd64.box
        % vagrant mutate lagopus01 libvirt

### ツール使い方
1. git clone する

        % git clone https://github.com/k-kosuga/vagrant-libvirt-custemplates
        % cd vagrant-libvirt-custemplates/

2. template を構築したい環境に合わせて変更する

        % vi ruby/templates/domain.xml.erb

3. Vagrantfile を構築したい環境に合わせて変更する

        % vi Vagrantfile

4. Vagrant の仮想環境起動

        % vagrant up --provider=libvirt

5. 今回の template は CPU の設定をいじっているので、
   ゲストでの /proc/cpuinfo は下記のようになる

        %  cat /proc/cpuinfo | egrep "processor|model name|flags"

        processor       : 0
        model name      : Intel Xeon E312xx (Sandy Bridge)
        flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx rdtscp lm constant_tsc rep_good nopl eagerfpu pni pclmulqdq vmx ssse3 cx16 pcid sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx f16c hypervisor lahf_lm xsaveopt vnmi ept fsgsbase smep erms
        processor       : 1
        model name      : Intel Xeon E312xx (Sandy Bridge)
        flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx rdtscp lm constant_tsc rep_good nopl eagerfpu pni pclmulqdq vmx ssse3 cx16 pcid sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx f16c hypervisor lahf_lm xsaveopt vnmi ept fsgsbase smep erms
        processor       : 2
        model name      : Intel Xeon E312xx (Sandy Bridge)
        flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx rdtscp lm constant_tsc rep_good nopl eagerfpu pni pclmulqdq vmx ssse3 cx16 pcid sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx f16c hypervisor lahf_lm xsaveopt vnmi ept fsgsbase smep erms
        processor       : 3
        model name      : Intel Xeon E312xx (Sandy Bridge)
        flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx rdtscp lm constant_tsc rep_good nopl eagerfpu pni pclmulqdq vmx ssse3 cx16 pcid sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx f16c hypervisor lahf_lm xsaveopt vnmi ept fsgsbase smep erms


中で何をやってるかの解説
---------------------------
### Vagrantfile
Vagrantfile は Ruby コードそのままなので、
_require\_relative_ で ライブラリを呼び出し、
該当メソッドに hook かえるようにする。

```ruby
require_relative 'ruby/custom_templates'
```

### ruby/custom_templates.rb
ここで、hook をかける。
対象のメソッドは、`VagrantPlugins#ProviderLibvirt#Util#ErbTemplate#to_xml()`。

alias_method() を使い、メソッドを付け替える。
to_xml() が呼ばれると、to_xml_new() を呼び、
その中で、必要であれば to_xml_ori() を呼ぶようにしている。

to_xml_new() 内では、
配下ディレクトリ内にある template を
ファイル名として取得できるように書き換えてある。

これで、hook がかかり、指定した template を呼び出すことができる。

ここでは、domain.xml.erb の template を対象としているが、
vagrant-libvirt の lib/vagrant-libvirt/templates/private_network.xml.erb など、
ネットワークの設定なのにも応用できる。

```ruby
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
```

### ruby/templates/domain.xml.erb
libvirt の domain の XML template。
