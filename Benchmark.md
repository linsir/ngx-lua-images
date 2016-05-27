## Benchmark
### 配置
渣配置

- CPU: Intel(R) Celeron(R) CPU G1620 @ 2.70GHz
- Memery: 2G

### ngx-lua-images v1.0:
```bash
[root@Master]# wrk -v -c10 -t8 -d30s "http://127.0.0.1:8000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1"
wrk 4.0.2 [epoll] Copyright (C) 2012 Will Glozer
Running 30s test @ http://127.0.0.1:8000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1
  8 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     1.87ms    6.05ms 222.50ms   99.53%
    Req/Sec   651.96     30.65     0.99k    98.62%
  155566 requests in 30.02s, 5.32GB read
Requests/sec:   5182.29
Transfer/sec:    181.50MB

[root@Master]# wrk -v -c50 -t8 -d30s "http://127.0.0.1:8000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1"
wrk 4.0.2 [epoll] Copyright (C) 2012 Will Glozer
Running 30s test @ http://127.0.0.1:8000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1
  8 threads and 50 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     9.72ms    4.70ms 211.24ms   97.62%
    Req/Sec   638.20     49.79     1.34k    88.07%
  152424 requests in 30.02s, 5.21GB read
Requests/sec:   5077.43
Transfer/sec:    177.83MB

[root@Master]# wrk -v -c100 -t8 -d30s "http://127.0.0.1:8000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1"
wrk 4.0.2 [epoll] Copyright (C) 2012 Will Glozer
Running 30s test @ http://127.0.0.1:8000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1
  8 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    22.16ms   34.10ms 878.75ms   97.87%
    Req/Sec   642.18     92.77     2.27k    90.27%
  152508 requests in 30.02s, 5.22GB read
Requests/sec:   5080.09
Transfer/sec:    177.92MB

```

### zimg v3.0.1
```bash
[root@Master]# wrk -v -c10 -t8 -d30s "http://127.0.0.1:5000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1"
wrk 4.0.2 [epoll] Copyright (C) 2012 Will Glozer
Running 30s test @ http://127.0.0.1:5000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1
  8 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    16.24ms   70.47ms 869.07ms   98.04%
    Req/Sec   118.51     15.91   171.00     69.61%
  27700 requests in 30.08s, 0.94GB read
  Socket errors: connect 0, read 27698, write 0, timeout 0
Requests/sec:    920.90
Transfer/sec:     31.98MB
[root@Master]# wrk -v -c50 -t8 -d30s "http://127.0.0.1:5000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1"
wrk 4.0.2 [epoll] Copyright (C) 2012 Will Glozer
Running 30s test @ http://127.0.0.1:5000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1
  8 threads and 50 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    48.00ms    3.51ms  88.86ms   73.85%
    Req/Sec   120.16      7.43   151.00     66.42%
  28803 requests in 30.09s, 0.98GB read
  Socket errors: connect 0, read 28801, write 0, timeout 0
Requests/sec:    957.33
Transfer/sec:     33.24MB
[root@Master]# wrk -v -c100 -t8 -d30s "http://127.0.0.1:5000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1"
wrk 4.0.2 [epoll] Copyright (C) 2012 Will Glozer
Running 30s test @ http://127.0.0.1:5000/f78350ae025ae71c3291e8d2d44af8de?w=100&h=100&g=1
  8 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    99.20ms    5.21ms 116.11ms   78.32%
    Req/Sec   118.71      6.70   150.00     69.29%
  28447 requests in 30.08s, 0.96GB read
  Socket errors: connect 0, read 28444, write 0, timeout 0
Requests/sec:    945.58
Transfer/sec:     32.84MB
```
### 结果
得益于 openresty 的高效（非阻塞，异步），结果是非常的出色。

 clients/     | ngx-lua-images v1.0 | zimg v3.0.1
-------|------|-----
10     | 5182.29 Requests/sec    | 920.90 Requests/sec
50     | 5077.43 Requests/sec    | 957.33 Requests/sec
100    | 5080.09 Requests/sec    | 945.58 Requests/sec

------
# ngx-lua-images with ceph

### 配置

- CPU: Intel(R) Core(TM) i5-4460  CPU @ 3.20GHz
- Memery: 8 G

###  结果
```bash
 wrk -v -c50 -t8 -d30s http://127.0.0.1:8000/abc/a.jpg\?g\=1\&w\=100                                                                                                                        
wrk 4.0.0 [epoll] Copyright (C) 2012 Will Glozer
Running 30s test @ http://127.0.0.1:8000/abc/a.jpg?g=1&w=100
  8 threads and 50 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     7.49ms    3.35ms 138.05ms   94.76%
    Req/Sec   822.92     85.09     1.44k    83.83%
  196645 requests in 30.02s, 6.37GB read
Requests/sec:   6550.74
Transfer/sec:    217.24MB

wrk -v -c100 -t8 -d30s http://127.0.0.1:8000/abc/a.jpg\?g\=1\&w\=100                                                                                                                       
wrk 4.0.0 [epoll] Copyright (C) 2012 Will Glozer
Running 30s test @ http://127.0.0.1:8000/abc/a.jpg?g=1&w=100
  8 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    16.79ms   21.94ms 672.69ms   98.40%
    Req/Sec   793.77    117.06     3.16k    90.40%
  189339 requests in 30.04s, 6.13GB read
Requests/sec:   6302.25
Transfer/sec:    209.00MB

```