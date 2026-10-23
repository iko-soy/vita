<p align="center"><img src="frontend/src/assets/vita.png" alt="vita" width="120"></p>

# 🛸 vita

keep track of your app distributions

this is a fork of [assemblycapital/vita](https://github.com/assemblycapital/vita), updated for kernel 408 and published from ~donmec-sallud. see [changes](#changes) for what differs from upstream.

to get downloads, `:vita` periodically scrys %cs /subs for each desk and caches the results.

`:vita` accepts foreign pokes attesting to activity on a desk.
`/lib/vita-client.hoon` helps any agent send vita activity pokes.
it sends at most one poke every 8 hours, and allows users to opt-in / opt-out depending on developer preference.

## vita downloads

on-init, vita will fetch 'downloader' metrics on all of your published desks and print them out to dojo.

```
vita: our %basket has 20 subs
vita: our %noodle has 12 subs
vita: our %houston has 133 subs
vita: our %radio has 326 subs
```

this tells you how many active urbit ships are signed up for OTAs for each desk.

you can run this routine whenever you want with `:vita|g`

`:vita` automatically checks `:treaty` for published desks.

to register a different desk (e.g. %kids), do `:vita|g %kids`

```
vita: our %kids has 0 subs
> :vita|g %kids
>=
```

now, whenever `:vita` does its full routine, `%kids` will be included.

```
vita: our %kids has 0 subs
vita: our %basket has 20 subs
vita: our %noodle has 12 subs
vita: our %houston has 133 subs
vita: our %radio has 326 subs
> :vita|g
>=
```

to unregister a desk: `:vita|d %kids`. WARNING: all data collected on an unregistered desk will be lost.

every 8 hours (by default), `:vita` grabs downloads metrics on each registered desk using `.^((set ship) %cs /=mydesk=/subs)`. every time this scry is performed, `:vita` logs the size of the set for that day. `:vita` keeps one copy of the latest full set of downloaders, and a cumulative set of all unique downloaders.

when users unsync from your local desk, `latest.downloads` wont go down until your next `|commit` to the desk.
`cumulative.downloads` only goes up.

to see all cumulative sizes: `=t +vita!total`

```
vita: %basket has 24 cumulative downloads
vita: %noodle has 14 cumulative downloads
vita: %houston has 139 cumulative downloads
vita: %radio has 359 cumulative downloads
> =t +vita!total
```

over time, `:vita` accumulates a `history=(map time [size=@ud set=(unit (set ship))])` for each desk.

to change the interval for automatic collection: `:vita|i ~h24` will change it to 24 hours from the default 8

to turn off the interval: `:vita|i` (no arg)

to enable collection of the full set of downloaders per day (instead of just the size) `:vita|f &`

## vita activity

`:vita` is also capable of collecting daily-active-users.

vita accepts `vita-action+[%activity =desk]` pokes from any source, for desks that are already registered with vita (pokes for unknown desks are rejected). it logs daily active users by adding users to a `latest=(set ship)`.
this set starts fresh each day. vita keeps record of the size of this set each day in `history.activity`

now you just need users to poke `:~your-planet/vita &vita-action [%activity %yourdesk]` every time they use your app.

`/lib/vita-client/hoon` has a wrapper agent which does just that.

to use it, copy over `<this_repo>/vita-client/*` into your app desk, then `/+  vita-client` and wrap your agent with

```hoon
%-  %-  agent:vita-client
    ::  data collection on/off by default
    :-  &
    ::  @p of your distributor ship
    ~sampel-palnet
...
```

you will also need to give the `(active:vita-client bowl)` card somewhere in your agent where real user activity can be detected (e.g. on-watch for a frontend subscription path). this card will induce `vita-client` to send activity upstream to the parent `vita`.

`vita-client` is initialized with a boolean (sets collection on/off by default), and the `@p` of your distributor ship (running vita, with the app registered).

users can turn `vita-client` data collection on/off with `:myagent +mydesk!enable-vita` or `:myagent +mydesk!disable-vita`.
this uses some generators packaged with vita-client. the actual poke is just `:myagent &vita-client [%set-enabled |]`

`vita-client` sends at most one activity poke every 8 hours.

## frontend

the vita frontend displays the data collected by `:vita` plus some forms for app creation and maintenance. the `:vita-deploy` agent supports app creation and maintenance.

the frontend is distributed as a glob served over ames by ~donmec-sallud. once your ship has fetched it, everything is served by your own ship: the app makes no requests to external services. the tile icon is inlined in `desk.docket-0` as a data URI.

desks created with `:vita-deploy` start with a glob hosted on your own ship; upload one from the frontend to fill it in.

# requirements

- kernel: `[%zuse 408]`
- `%landscape` (recommended): `%docket` serves the frontend, and `%treaty` provides the list of published desks and handles publishing from `:vita-deploy`. without it, `:vita` still collects metrics on desks registered with `:vita|g %desk`.

# installation

## install from livenet distribution

`|install ~donmec-sallud %vita`

[shelf.iko.soy](https://shelf.iko.soy) lists all the apps ~donmec-sallud offers.

## install from source

the desk is built with nix. `nix build` produces the complete desk in `./result`: the `vita/` sources plus their dependencies (`base-dev` from urbit `408k-2`, and docket/treaty from `%landscape`), pinned in `flake.lock`.

1. `nix build`
2. on your ship: `|new-desk %vita` and `|mount %vita`
3. replace the mounted desk with the build:
   ```
   rm -rf <my_pier>/vita/*
   cp -R result/. <my_pier>/vita/
   chmod -R u+w <my_pier>/vita
   ```
4. `|commit %vita`
5. `|install our %vita`

## building and hosting the glob

`nix build .#glob -o result-glob` builds the frontend into `./result-glob`.

to host it (as ~donmec-sallud does), install `%vita` on the hosting ship, then open `/docket/upload`, pick the `vita` desk and upload the `result-glob` directory. docket stores the glob and rewrites `desk.docket-0` on that ship with the new hash. copy that hash back into `vita/desk.docket-0` in this repo (it is `0v0` until then), otherwise the next `|commit` from the repo resets it.

then publish with `:treaty|publish %vita`.

# changes

changes from upstream [assemblycapital/vita](https://github.com/assemblycapital/vita) (last released for 411K from ~nodmyn-dosrux):

- **kernel 408.** `sys.kelvin` is now `[%zuse 408]` (urbit 408k-2). the kernel interfaces vita uses (clay `%cs /subs` and `%cd` scries, behn timers, hood `%kiln-install`/`%helm-pass`, spider threads, docket and treaty types) are unchanged, so no agent code changes were needed. support for 413–411 was dropped, since the bundled libraries are now the 408 ones.
- **nix flake.** `nix build` builds the installable desk and `nix build .#glob` builds the frontend, replacing the manual "copy in app dependencies" step.
- **glob hosted over ames.** the glob moved from an http bucket (DigitalOcean Spaces) to `glob-ames` on ~donmec-sallud, which is now also the publisher (`desk.ship`).
- **icon inlined in the docket.** the tile icon (`frontend/src/assets/vita.png`, losslessly recompressed) is embedded in `desk.docket-0` as a `data:` URI instead of being loaded from the bucket, so it shows even before the glob is fetched.
- **no external services.** new desks created by `:vita-deploy` default to a glob hosted on the creating ship instead of an example glob on the bucket.

## urbit.org grant

the original vita was funded by the urbit.org grant https://urbit.org/grants/app-metrics
