require 'sinatra'
require 'faraday'
require 'multi_json'
require 'CSV'

get '/' do
  erb :show
end

post '/product' do
  response = Faraday.get(internal_api(params))
  body = MultiJson.load(response.body)
  product = Faraday.get(get_product_api((body["product"]["code"] - 10000).to_s))
  p_body = MultiJson.load(product.body)
  MultiJson.dump(p_body["data"])
end

post '/download' do
  response = Faraday.get get_product_api(params["id"])
  a = MultiJson.load(response.body)
  map_data(a["data"].first)
end

post "/upload_from_csv" do
  CSV.foreach(params["datafile"][:tempfile].to_path, :headers => true) do |row|
    @data = row.to_hash
  end
  response = post_to_api(@data)
  raise response.body.inspect unless response.status == 200
  redirect "/"
end

post '/update' do
  response = post_to_api(params)
  raise response.body.inspect unless response.status == 200
  redirect "/"
end

def map_data(product)
  header = %w(id title handle body gross_price)
  CSV.open("new.csv", 'w') do |csv|
    csv << header
    csv << header.map{|h| product[h] }
  end
  send_file "new.csv"
end

def post_to_api(params)
  Faraday.put do |req|
    req.url 'http://www.dev.noths.com/api/admin/products/' + params["id"].to_s
    req.headers['Content-Type'] = 'application/json'
    req.body = MultiJson.dump({:id => params["id"], :product => params})
  end
end

def internal_api(params)
  'http://dev.noths.com/api/internal/products/from-uri?uri=' + params['uri']
end

def get_product_api(id)
  'http://www.dev.noths.com/admin/products.json?id=' + id
end