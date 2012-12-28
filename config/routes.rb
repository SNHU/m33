M33::Application.routes.draw do
  match '', :via => :post, :controller => "snhu_connector", :action => 'create'
  match '', :via => :get, :controller => "snhu_connector", :action => 'status'
end
