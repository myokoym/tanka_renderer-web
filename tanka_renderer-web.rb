# -*- coding: utf-8 -*-
require "sinatra"
require "haml"
require "tanka_renderer"

FONTS = {
  "KouzanBrushFontOTF" => "衡山毛筆フォント",
  "KouzanBrushFontGyousyo" => "衡山毛筆フォント行書",
  "KouzanBrushFontSousyo" => "衡山毛筆フォント草書",
  "AoyagiSosekiFont2" => "青柳疎石フォント2",
}

DIRECTIONS = {
  "vertical" => "縦書",
  "horizontal" => "横書",
}

get "/" do
  @fonts = FONTS
  @directions = DIRECTIONS
  @params ||= {}
  @params[:text] ||= default_text
  haml :index
end

post "/" do
  @fonts = FONTS
  @directions = DIRECTIONS
  begin
    @download_url = output_downloadable_file
  rescue => e
    return "Error: #{e}"
  end

  @params = params
  haml :index
end

helpers do
  def default_text
    <<-END_OF_TEXT
春はあけぼの やう／＼しろく成り行く
山ぎは すこしあかりて むらさきだちたる
雲のほそくたなびきたる

夏はよる 月の比はさら也 やみも猶
ほたるの多く飛びちがひたる
又 ただ一つ二つなどほのかに
うちひかりて行くもをかし

                           「枕草子」より
    END_OF_TEXT
  end

  def text
    @text ||= params[:text]
  end

  def filename
    return @filename if @filename
    @filename = params[:filename]
    @filename = Time.now.strftime("%Y%m%d%H%M%S") if @filename.empty?
    @filename << ".png" unless /.png\z/ =~ @filename
    @filename
  end

  def font
    @font ||= params[:font]
  end

  def vertical?
    params[:direction] == "vertical"
  end

  def output_downloadable_file
    today = Time.now.strftime("%Y%m%d")
    base_dir = "public/images/#{today}"
    FileUtils.mkdir_p(base_dir)
    output_path = File.join(base_dir, filename)

    renderer = TankaRenderer::Renderer::Image.new
    renderer.guess_font(font || "Gyousyo")
    renderer.vertical = false unless vertical?
    renderer.render(text, output_path)

    "#{base_url}/#{base_dir.gsub(/\Apublic\//, "")}/#{filename}"
  end

  def base_url
    parts_of_url = {
      :scheme => request.scheme,
      :host   => request.host,
      :port   => request.port,
      :path   => request.script_name,
    }
    URI::Generic.build(parts_of_url).to_s.gsub(/(#{request.scheme}:\/\/#{request.host}):80/, '\1')
  end
end
