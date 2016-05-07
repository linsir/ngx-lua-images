local prefix = '/home/files/'

config = {
    images_dir = prefix .. "images/", -- where images come from
    caches_dir = prefix .. "caches/", -- where images are cached
    timeout = 1600 -- * 24 * 3600 -- redis timeout (sec)
}