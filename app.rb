require 'rack'
require 'zip'
require 'tmpdir'

Object.send :remove_const, :App if defined?(App)
Object.send :remove_const, :INDEX_HTML if defined?(INDEX_HTML)
Object.send :remove_const, :EXTFILE_PREAMBLE if defined?(EXTFILE_PREAMBLE)
Object.send :remove_const, :INSTRUCTIONS_TEMPLATE if defined?(INSTRUCTIONS_TEMPLATE)
Object.send :remove_const, :GENERATE_CERTS_PATH if defined?(GENERATE_CERTS_PATH)

INSTRUCTIONS_TEMPLATE = File.join __dir__, '/INSTRUCTIONS.html'
GENERATE_CERTS_PATH = File.join __dir__, '/generate-certs'

index = ->(req) do
  [ 200, {'content-type' => 'text/html; charset=utf-8'}, [ INDEX_HTML ] ]
end

generate = ->(req) do
  begin
    san_entries = req.params['san_entries'].strip
    first_domain = StringIO.new(san_entries).readline.split('=', 2)[1].strip
    extfile_content = [ EXTFILE_PREAMBLE, san_entries ].join "\n"

    all_domains = StringIO.new(san_entries).readlines.map do |entry|
      k, v = entry.split('=', 2).map(&:strip)
      k =~ /DNS\.\d+/i ? v : nil
    end.compact.join " "

    install_instructions = File.read(INSTRUCTIONS_TEMPLATE) %
      { fqdn: first_domain, all_domains: all_domains }

    zip_content = nil
    Dir.mktmpdir do |dir|
      File.write "#{dir}/INSTRUCTIONS.html", install_instructions
      File.write "#{dir}/extfile", extfile_content
      if system "cd #{dir} && #{GENERATE_CERTS_PATH} #{first_domain} > output 2>&1"
        File.delete "#{dir}/output"
      else
        output = File.read "#{dir}/output"
        raise "Could not generate certificate. Please review your SAN entries. Output:\n#{output}"
      end
      stringio = Zip::OutputStream.write_buffer do |zio|
        Dir["#{dir}/*"].each do |fn|
          zio.put_next_entry File.basename fn
          zio.write File.read(fn)
        end
      end
      stringio.rewind
      zip_content = stringio.sysread
    end

    #return [ 200, {'content-type' => 'text/html; charset=utf-8'}, [ install_instructions ] ]

    #return [ 200, {'content-type' => 'text/plain; charset=utf-8'},
      #[ first_domain, "\n\n", extfile_content ] ]
    [ 200, {'content-type' => 'application/zip',
            'content-disposition' => 'attachment; filename="certs.zip"'}, [ zip_content ] ]
  rescue => e
    error_messages = [ "Could not generate certs: #{e.message}" ]
    (error_messages << "\n\n").concat e.backtrace unless ENV['RACK_ENV'] == 'production'
    [ 500, {'content-type' => 'text/plain'}, [ error_messages.join("\n") ] ]
  end
end

App = ->(env) do
  request = Rack::Request.new env
  unless request.path == '/'
    return [ 404, {'content-type' => 'text/plain'}, ['not found']]
  end
  request.get? ? index[request] : generate[request]
  #[ 200, {'content-type' => 'text/plain'}, [
    #[test_method[request], request.path, request.get?, request.post?].join("\n"),
    #"\n\n", request.methods.join("\n")] ]
end

EXTFILE_PREAMBLE = <<EXTFILE_PREAMBLE_END
[SAN]
subjectAltName = @alternate_names

[ alternate_names ]
EXTFILE_PREAMBLE_END

sample_san_entry = <<SAMPLE_SAN_ENTRY_END
DNS.1 = myapp.example.com
IP.1 = 127.0.0.1
IP.2 = 192.168.0.10
SAMPLE_SAN_ENTRY_END

index_html = <<INDEX_END
  <!doctype html>
  <html>
    <head>
      <title>SSL CA + app certs generator</title>
    </head>
    <body>
      <div>
        <form action="/" method="post">
          <div><label>Change the Subject Alternative Names above as you see fit.
          <textarea name="san_entries" rows="10" cols="80">%{sample_san_entry}</textarea>
          </textarea
          </label></div>
          <div><button type="submit">Generate certificate</button></div>
        </form>
        <p>The source-code is available at
          <a href="https://github.com/rosenfeld/cert-generator">Github</a>.</p>
      </div>
    </body>
  </html>
INDEX_END

INDEX_HTML = index_html % { sample_san_entry: sample_san_entry.chomp }
