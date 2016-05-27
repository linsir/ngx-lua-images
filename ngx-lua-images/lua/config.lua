local prefix = '/home/files/'

config = {
    images_dir = prefix .. "images/", -- where images come from
    caches_dir = prefix .. "caches/", -- where images are cached
    timeout = 300, -- * 24 * 3600 -- redis timeout (sec)
    ceph_mode = true,
    host = 'http://192.168.2.99',
    access_key = 'HXKJ2FLL7BAWENBMP0HF',
    secret_key = 'DEeFyCPlBKK2vS7DPJDeeozNiF5WAjL7pVMNpDlO',
    -- auth_uri = 'http://192.168.2.99/auth',
    -- swift_user = 'demouserid:swift',
    -- swift_secret_key  = 'QG1GXO1ZeKr62sUeCLkKge6SKRhpNNoBETqyhetG',

}