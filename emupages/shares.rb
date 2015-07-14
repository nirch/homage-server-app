#
# Emu shares test configurations
#
configure :test do
	# Emu Beta app settings
	set :emutest_shared_media, "http://media-test.emu.im"
	set :emutest_share_gif_page, "http://play-test.emu.im/giftest"
	set :emutest_xrc, "/emu-shares"
	set :emutest_app_page, "http://app-test.emu.im"
	set :emutest_fb_app_id, "428894703902516" # Emu Beta

	# Emu production app settings
	set :emu_shared_media, "http://media.emu.im"
	set :emu_share_gif_page, "http://play.emu.im/gif"
	set :emu_xrc, "/emu-shares"
	set :emu_app_page, "http://app.emu.im"
	set :emu_fb_app_id, "410672082391445" 
end

#
# Emu production configurations
#
configure :production do
	# Emu Beta app settings
	set :emutest_shared_media, "http://media-test.emu.im"
	set :emutest_share_gif_page, "http://play-test.emu.im/giftest"
	set :emutest_xrc, "/emu-shares"
	set :emutest_app_page, "http://app-test.emu.im"
	set :emutest_fb_app_id, "428894703902516" # Emu Beta

	# Emu production app settings
	set :emu_shared_media, "http://media.emu.im"
	set :emu_share_gif_page, "http://play.emu.im/gif"
	set :emu_xrc, "/emu-shares"
	set :emu_app_page, "http://app.emu.im"
	set :emu_fb_app_id, "410672082391445" 
end

# ------------------------
# Sharing gif page
# ------------------------
get '/gif/:oid' do
	oid = params["oid"]

	@oid = oid
	@xrc = settings.emu_xrc
	@shared_media = settings.emu_shared_media
	@fb_app_id = settings.emu_fb_app_id
	@gif_url = settings.emu_shared_media + "/" + oid + ".gif"
	@page_url = settings.emu_share_gif_page + "/" + oid
	@missing_gif_url = settings.emu_shared_media + "/" + "emu.gif"
	@app_url = settings.emu_app_page
	@mixpanel_token = settings.emumixpanel_token
	
	erb :emusharegif
end

get '/giftest/:oid' do
	oid = params["oid"]

	@oid = oid
	@xrc = settings.emutest_xrc
	@shared_media = settings.emutest_shared_media
	@fb_app_id = settings.emutest_fb_app_id
	@gif_url = settings.emutest_shared_media + "/" + oid + ".gif"
	@page_url = settings.emutest_share_gif_page + "/" + oid
	@missing_gif_url = settings.emutest_shared_media + "/" + "emu.gif"
	@app_url = settings.emutest_app_page
	@mixpanel_token = settings.emumixpanel_token

	erb :emusharegif
end


