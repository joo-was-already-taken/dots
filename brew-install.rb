require "tempfile"
require "fileutils"
require "open3"
require "optparse"

def sh!(cmd)
  system(cmd, exception: true)
end

modules = []

modules << {
  name: "core",
  brewfile: %(brew "stow"),
}

modules << {
  name: "herdr",
  brewfile: <<~BREW,
    brew "herdr"
    cargo "herdr-navigator", \
      source: "https://github.com/joo-was-already-taken/herdr-navigator.nvim"
    brew "bun"
    brew "fzf"
    brew "cargo"
  BREW
  postinstall: -> {
    sh! "herdr plugin install andrewchng/herdr-sessionizer --yes"
    sh! "herdr plugin install joo-was-already-taken/herdr-prevtab --yes"
    sh! "herdr plugin install speardragon/herdr-plugin-manager --yes"
  },
}

modules << {
  name: "neovim",
  brewfile: %(brew "neovim"\n) + File.read(File.join(__dir__, "neovim/.config/nvim/Brewfile")),
  postinstall: -> {
    sh! <<~SH
      git clone --depth=1 https://github.com/savq/paq-nvim.git \
        "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/paqs/start/paq-nvim || true
    SH
  },
}

modules << {
  name: "lazygit",
  brewfile: %(brew "lazygit"),
}

modules << {
  name: "zsh",
  brewfile: <<~BREW,
    brew "zsh-autosuggestions"
    brew "zsh-syntax-highlighting"
    brew "eza"
    brew "starship"
  BREW
}

options = {}
parser = OptionParser.new do |opts|
  opts.on("--brew PATH", "Path to the brew executable") do |path|
    options[:brew] = path
  end
end
parser.parse!(ARGV)
brew = options[:brew]
if brew
  abort "Brew executable not found or not executable: #{brew}" unless File.executable?(brew)
  brew_bin = File.dirname(File.expand_path(brew))
  ENV["PATH"] = "#{brew_bin}:#{ENV.fetch("PATH", "")}"
else
  brew = "brew"
end

args = ARGV.map(&:downcase)
modules_to_install = if args.empty?
  modules
else
  modules.select { |m| args.include?(m[:name].downcase) }
end

if modules_to_install.empty?
  puts "No matching modules found for: #{ARGV.join(', ')}"
  puts "Available modules: #{modules.map { |m| m[:name] }.join(', ')}"
  exit 1
end

brewfile_content = modules_to_install.map { |m| m[:brewfile] }.compact.join("\n")

temp_brewfile = Tempfile.new("Brewfile")
temp_brewfile.write(brewfile_content)
temp_brewfile.close

stdout, stderr, status = Open3.capture3(brew, "bundle", "--file=#{temp_brewfile.path}")

temp_brewfile.unlink

unless status.success?
  puts "Homebrew failed to install dependencies. Aborting hooks. error: #{stderr}"
  exit 1
end

modules_to_install.each do |mod|
  next unless mod[:postinstall].respond_to?(:call)
  begin
    mod[:postinstall].call
  rescue StandardError => e
    puts "Postinstall hook failed for #{mod[:name]}: #{e.message}"
  end
end
