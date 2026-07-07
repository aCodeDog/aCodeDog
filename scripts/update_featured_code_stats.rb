#!/usr/bin/env ruby

require "cgi"
require "date"
require "fileutils"
require "json"
require "net/http"
require "uri"

if ENV["HTTP_PROXY"] && !ENV["http_proxy"]
  ENV["http_proxy"] = ENV["HTTP_PROXY"]
  ENV.delete("HTTP_PROXY")
end

ROOT = File.expand_path("..", __dir__)
README_PATH = File.join(ROOT, "README.md")
SVG_PATH = File.join(ROOT, "assets", "featured-code-stats.svg")
START_MARKER = "<!-- FEATURED-CODE-STATS:START -->"
END_MARKER = "<!-- FEATURED-CODE-STATS:END -->"

REPOS = [
  {
    title: "PMT",
    repo: "Mondo-Robotics/PMT",
    page: "https://acodedog.github.io/perceptive-bfm/",
    domain: "Behavior Foundation Model",
    color: "#D946EF"
  },
  {
    title: "UniLab",
    repo: "unilabsim/UniLab",
    page: "https://unilabsim.github.io/",
    domain: "Heterogeneous RL",
    color: "#17B890"
  },
  {
    title: "OmniPerception",
    repo: "aCodeDog/OmniPerception",
    page: "https://acodedog.github.io/OmniPerceptionPages/",
    domain: "Legged Perception",
    color: "#2F80ED"
  },
  {
    title: "GS-Playground",
    repo: "discoverse-dev/gs_playground",
    page: "https://gsplayground.github.io/",
    domain: "Simulation",
    color: "#F59E0B"
  },
  {
    title: "Legged Robots Manipulation",
    repo: "aCodeDog/legged-robots-manipulation",
    page: nil,
    domain: "Loco-Manipulation",
    color: "#E85D75"
  },
  {
    title: "DiT4DiT",
    repo: "Mondo-Robotics/DiT4DiT",
    page: "https://dit4dit.github.io/",
    domain: "Robot Control",
    color: "#8B5CF6"
  },
  {
    title: "Awesome Loco-Manipulation",
    repo: "aCodeDog/awesome-loco-manipulation",
    page: nil,
    domain: "Reading List",
    color: "#06B6D4"
  },
  {
    title: "Genesis Legged Gym",
    repo: "aCodeDog/genesis_legged_gym",
    page: nil,
    domain: "Training Framework",
    color: "#84CC16"
  }
].freeze

def fetch_repo(repo)
  uri = URI("https://api.github.com/repos/#{repo}")
  request = Net::HTTP::Get.new(uri)
  request["Accept"] = "application/vnd.github+json"
  request["User-Agent"] = "aCodeDog-profile-stats"

  token = ENV["GITHUB_TOKEN"]
  request["Authorization"] = "Bearer #{token}" if token && !token.empty?

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  raise "GitHub API error for #{repo}: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

  JSON.parse(response.body)
end

def format_number(value)
  value.to_i.to_s.reverse.scan(/.{1,3}/).join(",").reverse
end

def xml(text)
  CGI.escapeHTML(text.to_s)
end

def row_svg(repo, index, max_stars, bar_width)
  y = 206 + (index * 54)
  width = [(repo.fetch(:stars).to_f / max_stars * bar_width).round, 12].max
  title = xml(repo.fetch(:title))
  domain = xml(repo.fetch(:domain))
  repo_name = xml(repo.fetch(:repo))
  stars = format_number(repo.fetch(:stars))
  forks = format_number(repo.fetch(:forks))
  color = repo.fetch(:color)

  <<~SVG
    <g transform="translate(398 #{y})">
      <text x="0" y="0" class="repo-title">#{title}</text>
      <text x="0" y="18" class="repo-meta">#{repo_name} / #{domain}</text>
      <rect x="0" y="26" width="#{bar_width}" height="11" rx="5.5" fill="#E9EEF7"/>
      <rect x="0" y="26" width="#{width}" height="11" rx="5.5" fill="#{color}"/>
      <circle cx="#{width}" cy="31.5" r="7" fill="#{color}" opacity="0.2"/>
      <circle cx="#{width}" cy="31.5" r="3.5" fill="#{color}"/>
      <text x="468" y="7" class="repo-stars">#{stars}</text>
      <text x="468" y="25" class="repo-forks">#{forks} forks</text>
    </g>
  SVG
end

stats = REPOS.map do |repo|
  api_data = fetch_repo(repo.fetch(:repo))
  repo.merge(
    stars: api_data.fetch("stargazers_count"),
    forks: api_data.fetch("forks_count"),
    github_url: api_data.fetch("html_url")
  )
end

stats.sort_by! { |repo| -repo.fetch(:stars) }

total_stars = stats.sum { |repo| repo.fetch(:stars) }
total_forks = stats.sum { |repo| repo.fetch(:forks) }
max_stars = stats.map { |repo| repo.fetch(:stars) }.max
updated_at = ENV.fetch("GITHUB_STATS_DATE", Date.today.to_s)
bar_width = 380
circumference = 578
arc = (circumference * 0.76).round

FileUtils.mkdir_p(File.dirname(SVG_PATH)) unless Dir.exist?(File.dirname(SVG_PATH))

svg = <<~SVG
  <svg width="960" height="720" viewBox="0 0 960 720" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="title desc">
    <title id="title">Featured code GitHub stats for Zifan Wang</title>
    <desc id="desc">A robotics dashboard visualizing stars and forks across featured repositories.</desc>
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="960" y2="720" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#FFFFFF"/>
        <stop offset="0.48" stop-color="#F8FBFF"/>
        <stop offset="1" stop-color="#FFF7F3"/>
      </linearGradient>
      <linearGradient id="headline" x1="72" y1="64" x2="805" y2="142" gradientUnits="userSpaceOnUse">
        <stop stop-color="#16325C"/>
        <stop offset="0.52" stop-color="#E85D75"/>
        <stop offset="1" stop-color="#17B890"/>
      </linearGradient>
      <filter id="softShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="0" dy="12" stdDeviation="18" flood-color="#16325C" flood-opacity="0.12"/>
      </filter>
      <style>
        text { font-family: Arial, Helvetica, sans-serif; letter-spacing: 0; }
        .label { fill: #60708A; font-size: 13px; font-weight: 600; }
        .title { fill: url(#headline); font-size: 34px; font-weight: 800; }
        .subtitle { fill: #526174; font-size: 15px; font-weight: 500; }
        .metric { fill: #16325C; font-size: 46px; font-weight: 800; }
        .metric-small { fill: #16325C; font-size: 24px; font-weight: 800; }
        .repo-title { fill: #16325C; font-size: 15px; font-weight: 700; }
        .repo-meta { fill: #6B778C; font-size: 11px; font-weight: 500; }
        .repo-stars { fill: #16325C; font-size: 16px; font-weight: 800; text-anchor: end; }
        .repo-forks { fill: #6B778C; font-size: 11px; font-weight: 600; text-anchor: end; }
      </style>
    </defs>

    <rect width="960" height="720" rx="24" fill="url(#bg)"/>
    <rect x="30" y="28" width="900" height="664" rx="22" fill="#FFFFFF" filter="url(#softShadow)"/>
    <rect x="31" y="29" width="898" height="662" rx="21" stroke="#E4EAF4"/>

    <text x="70" y="82" class="label">FEATURED CODE SIGNAL</text>
    <text x="70" y="124" class="title">Robotics GitHub Dashboard</text>
    <text x="70" y="153" class="subtitle">Stars across robot learning, simulation, perception, and loco-manipulation repositories.</text>

    <g transform="translate(68 200)">
      <rect width="280" height="272" rx="18" fill="#F7FAFE" stroke="#E4EAF4"/>
      <circle cx="140" cy="116" r="92" fill="none" stroke="#E8EEF7" stroke-width="18"/>
      <circle cx="140" cy="116" r="92" fill="none" stroke="#E85D75" stroke-width="18" stroke-linecap="round" stroke-dasharray="#{arc} #{circumference}" transform="rotate(-90 140 116)"/>
      <circle cx="140" cy="116" r="64" fill="none" stroke="#17B890" stroke-width="10" stroke-linecap="round" stroke-dasharray="270 #{circumference}" transform="rotate(-32 140 116)"/>
      <text x="140" y="105" class="metric" text-anchor="middle">#{format_number(total_stars)}</text>
      <text x="140" y="132" class="label" text-anchor="middle">tracked stars</text>

      <g transform="translate(28 210)">
        <rect width="66" height="44" rx="12" fill="#FFFFFF" stroke="#E4EAF4"/>
        <text x="33" y="21" class="metric-small" text-anchor="middle">#{stats.length}</text>
        <text x="33" y="36" class="label" text-anchor="middle">repos</text>
      </g>
      <g transform="translate(106 210)">
        <rect width="72" height="44" rx="12" fill="#FFFFFF" stroke="#E4EAF4"/>
        <text x="36" y="21" class="metric-small" text-anchor="middle">#{format_number(total_forks)}</text>
        <text x="36" y="36" class="label" text-anchor="middle">forks</text>
      </g>
      <g transform="translate(190 210)">
        <rect width="62" height="44" rx="12" fill="#FFFFFF" stroke="#E4EAF4"/>
        <text x="31" y="21" class="metric-small" text-anchor="middle">#{format_number(max_stars)}</text>
        <text x="31" y="36" class="label" text-anchor="middle">top</text>
      </g>
    </g>

    <text x="398" y="192" class="label">REPOSITORY STAR DISTRIBUTION</text>
    #{stats.each_with_index.map { |repo, index| row_svg(repo, index, max_stars, bar_width) }.join("\n")}

    <g transform="translate(70 652)">
      <rect width="820" height="1" fill="#E4EAF4"/>
      <text x="0" y="28" class="subtitle">Updated #{xml(updated_at)} UTC from the GitHub API.</text>
      <text x="820" y="28" class="subtitle" text-anchor="end">Robot learning code portfolio</text>
    </g>
  </svg>
SVG

File.write(SVG_PATH, svg)

readme = File.read(README_PATH)
block = <<~MARKDOWN.strip
  #{START_MARKER}
  <div align="center">
    <img src="./assets/featured-code-stats.svg" alt="Featured code GitHub stats visualization" width="100%"/>
  </div>
  #{END_MARKER}
MARKDOWN

pattern = /#{Regexp.escape(START_MARKER)}.*?#{Regexp.escape(END_MARKER)}/m
raise "Could not find featured code stats markers in README.md" unless readme.match?(pattern)

File.write(README_PATH, readme.sub(pattern, block))
