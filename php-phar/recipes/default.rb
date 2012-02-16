php_version = node[:php_phar][:version]
php_cmd     = "/usr/local/bin/php"
php_ext_dir = `#{php_cmd} -r 'echo ini_get("extension_dir");'`.strip

if php_ext_dir.empty?
  raise "Could not determine PHP's extension_dir"
end

package "autoconf"

remote_file "/tmp/php-#{php_version}.tar.gz" do
  source "http://us.php.net/get/php-#{php_version}.tar.gz/from/us.php.net/mirror"
end

execute "test tar" do
  command "tar -zxvf php-#{php_version}.tar.gz"
  cwd     "/tmp"
  only_if do
    File.exists?("/tmp/php-#{php_version}.tar.gz")
  end
end

execute "extract tar" do
  command "tar -zxvf php-#{php_version}.tar.gz"
  cwd     "/tmp"
  creates "/tmp/php-#{php_version}"
  only_if do
    File.exists?("/tmp/php-#{php_version}.tar.gz")
  end
end

execute "phpize" do
  cwd "/tmp/php-#{php_version}/ext/phar"
  not_if do
    File.exists?("/tmp/php-#{php_version}/modules/phar.so")
  end
end

# the CFLAGS are experimental
execute "build phar" do
  command 'CFLAGS="-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64" ./configure --disable-all --enable-phar=shared && make'
  cwd     "/tmp/php-#{php_version}/ext/phar"
  not_if do
    File.exists?("/tmp/php-#{php_version}/modules/phar.so")
  end
end

execute "copy phar.so" do
  command "cp modules/phar.so #{php_ext_dir}"
  cwd     "/tmp/php-#{php_version}/ext/phar"
  not_if do
    File.exists?("#{php_ext_dir}/phar.so")
  end
end

include_recipe "php-phar::configure"
