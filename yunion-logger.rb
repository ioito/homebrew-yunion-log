class YunionLogger < Formula
  desc "Yunion Cloud Logger Controller server"
  homepage "https://github.com/yunionio/onecloud.git"
  version_scheme 1
  head "https://github.com/yunionio/onecloud.git",
    :branch      => "master"

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath

    (buildpath/"src/yunion.io/x/onecloud").install buildpath.children
    cd buildpath/"src/yunion.io/x/onecloud" do
      system "make", "cmd/logger"
      bin.install "_output/bin/logger"
      prefix.install_metafiles
    end

    (buildpath/"logger.conf").write logger_conf
    etc.install "logger.conf"
  end

  def post_install
    (var/"log/logger").mkpath
  end

  def logger_conf; <<~EOS
  region = 'Yunion'
  address = '127.0.0.1'
  port = 9999
  auth_uri = 'http://127.0.0.1:35357/v3'
  admin_user = 'sysadmin'
  admin_password = 'sysadmin'
  admin_tenant_name = 'system'
  sql_connection = 'mysql+pymysql://root:password@127.0.0.1:3306/yunionlogger?charset=utf8'

  auto_sync_table = True

  enable_ssl = false
  ssl_certfile = '/opt/yunionsetup/config/keys/log/log.crt'
  ssl_keyfile = '/opt/yunionsetup/config/keys/log/log.key'
  ssl_ca_certs = '/opt/yunionsetup/config/keys/log/ca.crt'
  EOS
  end

  def caveats; <<~EOS
    Change #{etc}/logger.conf sql_connection options and create yunionlogger database
    brew services start yunion-log
    source #{etc}/keystone/config/rc_admin
    climc service-create --enabled log log
    climc endpoint-create --enabled log Yunion public http://127.0.0.1:9999
    climc endpoint-create --enabled log Yunion internal http://127.0.0.1:9999
    climc endpoint-create --enabled log Yunion admin http://127.0.0.1:9999

    brew services restart yunion-yunionapi
  EOS
  end


  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>RunAtLoad</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/logger</string>
        <string>--conf</string>
        <string>#{etc}/logger.conf</string>
        <string>--auto-sync-table</string>
      </array>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
      <key>StandardErrorPath</key>
      <string>#{var}/log/logger/output.log</string>
      <key>StandardOutPath</key>
      <string>#{var}/log/logger/output.log</string>
    </dict>
    </plist>
  EOS
  end

  test do
    system "false"
  end
end
