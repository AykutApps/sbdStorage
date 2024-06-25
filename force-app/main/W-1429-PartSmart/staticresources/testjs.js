/*! For license information please see stream.js.LICENSE.txt */
(() => {
    var e = {
            411: function (e) {
                e.exports = (function () {
                    "use strict";
                    var e = Object.prototype.toString,
                        t =
                            Array.isArray ||
                            function (t) {
                                return "[object Array]" === e.call(t);
                            };
                    function n(e) {
                        return "function" == typeof e;
                    }
                    function r(e) {
                        return t(e) ? "array" : typeof e;
                    }
                    function o(e) {
                        return e.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&");
                    }
                    function i(e, t) {
                        return null != e && "object" == typeof e && t in e;
                    }
                    function a(e, t) {
                        return null != e && "object" != typeof e && e.hasOwnProperty && e.hasOwnProperty(t);
                    }
                    var s = RegExp.prototype.test;
                    function c(e, t) {
                        return s.call(e, t);
                    }
                    var l = /\S/;
                    function u(e) {
                        return !c(l, e);
                    }
                    var p = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;", "/": "&#x2F;", "`": "&#x60;", "=": "&#x3D;" };
                    function d(e) {
                        return String(e).replace(/[&<>"'`=\/]/g, function (e) {
                            return p[e];
                        });
                    }
                    var f = /\s*/,
                        h = /\s+/,
                        g = /\s*=/,
                        m = /\s*\}/,
                        v = /#|\^|\/|>|\{|&|=|!/;
                    function w(e, n) {
                        if (!e) return [];
                        var r,
                            i,
                            a,
                            s = !1,
                            c = [],
                            l = [],
                            p = [],
                            d = !1,
                            w = !1,
                            C = "",
                            E = 0;
                        function x() {
                            if (d && !w) for (; p.length; ) delete l[p.pop()];
                            else p = [];
                            (d = !1), (w = !1);
                        }
                        function M(e) {
                            if (("string" == typeof e && (e = e.split(h, 2)), !t(e) || 2 !== e.length)) throw new Error("Invalid tags: " + e);
                            (r = new RegExp(o(e[0]) + "\\s*")), (i = new RegExp("\\s*" + o(e[1]))), (a = new RegExp("\\s*" + o("}" + e[1])));
                        }
                        M(n || S.tags);
                        for (var O, j, _, T, R, A, P = new k(e); !P.eos(); ) {
                            if (((O = P.pos), (_ = P.scanUntil(r))))
                                for (var U = 0, I = _.length; U < I; ++U)
                                    u((T = _.charAt(U))) ? (p.push(l.length), (C += T)) : ((w = !0), (s = !0), (C += " ")),
                                        l.push(["text", T, O, O + 1]),
                                        (O += 1),
                                        "\n" === T && (x(), (C = ""), (E = 0), (s = !1));
                            if (!P.scan(r)) break;
                            if (
                                ((d = !0),
                                (j = P.scan(v) || "name"),
                                P.scan(f),
                                "=" === j
                                    ? ((_ = P.scanUntil(g)), P.scan(g), P.scanUntil(i))
                                    : "{" === j
                                    ? ((_ = P.scanUntil(a)), P.scan(m), P.scanUntil(i), (j = "&"))
                                    : (_ = P.scanUntil(i)),
                                !P.scan(i))
                            )
                                throw new Error("Unclosed tag at " + P.pos);
                            if (((R = ">" == j ? [j, _, O, P.pos, C, E, s] : [j, _, O, P.pos]), E++, l.push(R), "#" === j || "^" === j)) c.push(R);
                            else if ("/" === j) {
                                if (!(A = c.pop())) throw new Error('Unopened section "' + _ + '" at ' + O);
                                if (A[1] !== _) throw new Error('Unclosed section "' + A[1] + '" at ' + O);
                            } else "name" === j || "{" === j || "&" === j ? (w = !0) : "=" === j && M(_);
                        }
                        if ((x(), (A = c.pop()))) throw new Error('Unclosed section "' + A[1] + '" at ' + P.pos);
                        return b(y(l));
                    }
                    function y(e) {
                        for (var t, n, r = [], o = 0, i = e.length; o < i; ++o)
                            (t = e[o]) && ("text" === t[0] && n && "text" === n[0] ? ((n[1] += t[1]), (n[3] = t[3])) : (r.push(t), (n = t)));
                        return r;
                    }
                    function b(e) {
                        for (var t, n = [], r = n, o = [], i = 0, a = e.length; i < a; ++i)
                            switch ((t = e[i])[0]) {
                                case "#":
                                case "^":
                                    r.push(t), o.push(t), (r = t[4] = []);
                                    break;
                                case "/":
                                    (o.pop()[5] = t[2]), (r = o.length > 0 ? o[o.length - 1][4] : n);
                                    break;
                                default:
                                    r.push(t);
                            }
                        return n;
                    }
                    function k(e) {
                        (this.string = e), (this.tail = e), (this.pos = 0);
                    }
                    function C(e, t) {
                        (this.view = e), (this.cache = { ".": this.view }), (this.parent = t);
                    }
                    function E() {
                        this.templateCache = {
                            _cache: {},
                            set: function (e, t) {
                                this._cache[e] = t;
                            },
                            get: function (e) {
                                return this._cache[e];
                            },
                            clear: function () {
                                this._cache = {};
                            }
                        };
                    }
                    (k.prototype.eos = function () {
                        return "" === this.tail;
                    }),
                        (k.prototype.scan = function (e) {
                            var t = this.tail.match(e);
                            if (!t || 0 !== t.index) return "";
                            var n = t[0];
                            return (this.tail = this.tail.substring(n.length)), (this.pos += n.length), n;
                        }),
                        (k.prototype.scanUntil = function (e) {
                            var t,
                                n = this.tail.search(e);
                            switch (n) {
                                case -1:
                                    (t = this.tail), (this.tail = "");
                                    break;
                                case 0:
                                    t = "";
                                    break;
                                default:
                                    (t = this.tail.substring(0, n)), (this.tail = this.tail.substring(n));
                            }
                            return (this.pos += t.length), t;
                        }),
                        (C.prototype.push = function (e) {
                            return new C(e, this);
                        }),
                        (C.prototype.lookup = function (e) {
                            var t,
                                r = this.cache;
                            if (r.hasOwnProperty(e)) t = r[e];
                            else {
                                for (var o, s, c, l = this, u = !1; l; ) {
                                    if (e.indexOf(".") > 0)
                                        for (o = l.view, s = e.split("."), c = 0; null != o && c < s.length; )
                                            c === s.length - 1 && (u = i(o, s[c]) || a(o, s[c])), (o = o[s[c++]]);
                                    else (o = l.view[e]), (u = i(l.view, e));
                                    if (u) {
                                        t = o;
                                        break;
                                    }
                                    l = l.parent;
                                }
                                r[e] = t;
                            }
                            return n(t) && (t = t.call(this.view)), t;
                        }),
                        (E.prototype.clearCache = function () {
                            void 0 !== this.templateCache && this.templateCache.clear();
                        }),
                        (E.prototype.parse = function (e, t) {
                            var n = this.templateCache,
                                r = e + ":" + (t || S.tags).join(":"),
                                o = void 0 !== n,
                                i = o ? n.get(r) : void 0;
                            return null == i && ((i = w(e, t)), o && n.set(r, i)), i;
                        }),
                        (E.prototype.render = function (e, t, n, r) {
                            var o = this.getConfigTags(r),
                                i = this.parse(e, o),
                                a = t instanceof C ? t : new C(t, void 0);
                            return this.renderTokens(i, a, n, e, r);
                        }),
                        (E.prototype.renderTokens = function (e, t, n, r, o) {
                            for (var i, a, s, c = "", l = 0, u = e.length; l < u; ++l)
                                (s = void 0),
                                    "#" === (a = (i = e[l])[0])
                                        ? (s = this.renderSection(i, t, n, r, o))
                                        : "^" === a
                                        ? (s = this.renderInverted(i, t, n, r, o))
                                        : ">" === a
                                        ? (s = this.renderPartial(i, t, n, o))
                                        : "&" === a
                                        ? (s = this.unescapedValue(i, t))
                                        : "name" === a
                                        ? (s = this.escapedValue(i, t, o))
                                        : "text" === a && (s = this.rawValue(i)),
                                    void 0 !== s && (c += s);
                            return c;
                        }),
                        (E.prototype.renderSection = function (e, r, o, i, a) {
                            var s = this,
                                c = "",
                                l = r.lookup(e[1]);
                            function u(e) {
                                return s.render(e, r, o, a);
                            }
                            if (l) {
                                if (t(l)) for (var p = 0, d = l.length; p < d; ++p) c += this.renderTokens(e[4], r.push(l[p]), o, i, a);
                                else if ("object" == typeof l || "string" == typeof l || "number" == typeof l) c += this.renderTokens(e[4], r.push(l), o, i, a);
                                else if (n(l)) {
                                    if ("string" != typeof i) throw new Error("Cannot use higher-order sections without the original template");
                                    null != (l = l.call(r.view, i.slice(e[3], e[5]), u)) && (c += l);
                                } else c += this.renderTokens(e[4], r, o, i, a);
                                return c;
                            }
                        }),
                        (E.prototype.renderInverted = function (e, n, r, o, i) {
                            var a = n.lookup(e[1]);
                            if (!a || (t(a) && 0 === a.length)) return this.renderTokens(e[4], n, r, o, i);
                        }),
                        (E.prototype.indentPartial = function (e, t, n) {
                            for (var r = t.replace(/[^ \t]/g, ""), o = e.split("\n"), i = 0; i < o.length; i++) o[i].length && (i > 0 || !n) && (o[i] = r + o[i]);
                            return o.join("\n");
                        }),
                        (E.prototype.renderPartial = function (e, t, r, o) {
                            if (r) {
                                var i = this.getConfigTags(o),
                                    a = n(r) ? r(e[1]) : r[e[1]];
                                if (null != a) {
                                    var s = e[6],
                                        c = e[5],
                                        l = e[4],
                                        u = a;
                                    0 == c && l && (u = this.indentPartial(a, l, s));
                                    var p = this.parse(u, i);
                                    return this.renderTokens(p, t, r, u, o);
                                }
                            }
                        }),
                        (E.prototype.unescapedValue = function (e, t) {
                            var n = t.lookup(e[1]);
                            if (null != n) return n;
                        }),
                        (E.prototype.escapedValue = function (e, t, n) {
                            var r = this.getConfigEscape(n) || S.escape,
                                o = t.lookup(e[1]);
                            if (null != o) return "number" == typeof o && r === S.escape ? String(o) : r(o);
                        }),
                        (E.prototype.rawValue = function (e) {
                            return e[1];
                        }),
                        (E.prototype.getConfigTags = function (e) {
                            return t(e) ? e : e && "object" == typeof e ? e.tags : void 0;
                        }),
                        (E.prototype.getConfigEscape = function (e) {
                            return e && "object" == typeof e && !t(e) ? e.escape : void 0;
                        });
                    var S = {
                            name: "mustache.js",
                            version: "4.2.0",
                            tags: ["{{", "}}"],
                            clearCache: void 0,
                            escape: void 0,
                            parse: void 0,
                            render: void 0,
                            Scanner: void 0,
                            Context: void 0,
                            Writer: void 0,
                            set templateCache(e) {
                                x.templateCache = e;
                            },
                            get templateCache() {
                                return x.templateCache;
                            }
                        },
                        x = new E();
                    return (
                        (S.clearCache = function () {
                            return x.clearCache();
                        }),
                        (S.parse = function (e, t) {
                            return x.parse(e, t);
                        }),
                        (S.render = function (e, t, n, o) {
                            if ("string" != typeof e)
                                throw new TypeError(
                                    'Invalid template! Template should be a "string" but "' +
                                        r(e) +
                                        '" was given as the first argument for mustache#render(template, view, partials)'
                                );
                            return x.render(e, t, n, o);
                        }),
                        (S.escape = d),
                        (S.Scanner = k),
                        (S.Context = C),
                        (S.Writer = E),
                        S
                    );
                })();
            },
            118: (e, t) => {
                "use strict";
                Object.defineProperty(t, "__esModule", { value: !0 }), (t.Channel = void 0);
                var n = (function () {
                    var e = Math.floor(1000001 * Math.random()),
                        t = {};
                    function n(e) {
                        return Array.isArray ? Array.isArray(e) : -1 != e.constructor.toString().indexOf("Array");
                    }
                    var r = {},
                        o = function (e) {
                            try {
                                var n = JSON.parse(e.data);
                                if ("object" != typeof n || null === n) throw "malformed";
                            } catch (e) {
                                return;
                            }
                            var o,
                                i,
                                a,
                                s = e.source,
                                c = e.origin;
                            if ("string" == typeof n.method) {
                                var l = n.method.split("::");
                                2 == l.length ? ((o = l[0]), (a = l[1])) : (a = n.method);
                            }
                            if ((void 0 !== n.id && (i = n.id), "string" == typeof a)) {
                                var u = !1;
                                if (t[c] && t[c][o])
                                    for (var p = 0; p < t[c][o].length; p++)
                                        if (t[c][o][p].win === s) {
                                            t[c][o][p].handler(c, a, n), (u = !0);
                                            break;
                                        }
                                if (!u && t["*"] && t["*"][o])
                                    for (p = 0; p < t["*"][o].length; p++)
                                        if (t["*"][o][p].win === s) {
                                            t["*"][o][p].handler(c, a, n);
                                            break;
                                        }
                            } else void 0 !== i && r[i] && r[i](c, a, n);
                        };
                    return (
                        window.addEventListener ? window.addEventListener("message", o, !1) : window.attachEvent && window.attachEvent("onmessage", o),
                        {
                            build: function (o) {
                                var i = function (e) {
                                    if (o.debugOutput && window.console && window.console.log) {
                                        try {
                                            "string" != typeof e && (e = JSON.stringify(e));
                                        } catch (e) {}
                                        console.log("[" + c + "] " + e);
                                    }
                                };
                                if (!window.postMessage) throw "jschannel cannot run this browser, no postMessage";
                                if (!window.JSON || !window.JSON.stringify || !window.JSON.parse) throw "jschannel cannot run this browser, no JSON parsing/serialization";
                                if ("object" != typeof o) throw "Channel build invoked without a proper object argument";
                                if (!o.window || !o.window.postMessage) throw "Channel.build() called without a valid window argument";
                                if (window === o.window) throw "target window is same as present window -- not allowed";
                                var a,
                                    s = !1;
                                if (
                                    ("string" == typeof o.origin &&
                                        ("*" === o.origin
                                            ? (s = !0)
                                            : null !== (a = o.origin.match(/^https?:\/\/(?:[-a-zA-Z0-9_\.])+(?::\d+)?/)) && ((o.origin = a[0].toLowerCase()), (s = !0))),
                                    !s)
                                )
                                    throw "Channel.build() called with an invalid origin";
                                if (void 0 !== o.scope) {
                                    if ("string" != typeof o.scope) throw "scope, when specified, must be a string";
                                    if (o.scope.split("::").length > 1) throw "scope may not contain double colons: '::'";
                                }
                                var c = (function () {
                                        for (var e = "", t = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", n = 0; n < 5; n++)
                                            e += t.charAt(Math.floor(62 * Math.random()));
                                        return e;
                                    })(),
                                    l = {},
                                    u = {},
                                    p = {},
                                    d = !1,
                                    f = [],
                                    h = function (e, t, a) {
                                        if ("function" == typeof o.gotMessageObserver)
                                            try {
                                                o.gotMessageObserver(e, a);
                                            } catch (e) {
                                                i("gotMessageObserver() raised an exception: " + e.toString());
                                            }
                                        if (a.id && t) {
                                            if (l[t]) {
                                                var s = (function (e, t, n) {
                                                    var r = !1,
                                                        o = !1;
                                                    return {
                                                        origin: t,
                                                        invoke: function (t, r) {
                                                            if (!p[e]) throw "attempting to invoke a callback of a nonexistent transaction: " + e;
                                                            for (var o = !1, i = 0; i < n.length; i++)
                                                                if (t === n[i]) {
                                                                    o = !0;
                                                                    break;
                                                                }
                                                            if (!o) throw "request supports no such callback '" + t + "'";
                                                            m({ id: e, callback: t, params: r });
                                                        },
                                                        error: function (t, n) {
                                                            if (((o = !0), !p[e])) throw "error called for nonexistent message: " + e;
                                                            delete p[e], m({ id: e, error: t, message: n });
                                                        },
                                                        complete: function (t) {
                                                            if (((o = !0), !p[e])) throw "complete called for nonexistent message: " + e;
                                                            delete p[e], m({ id: e, result: t });
                                                        },
                                                        delayReturn: function (e) {
                                                            return "boolean" == typeof e && (r = !0 === e), r;
                                                        },
                                                        completed: function () {
                                                            return o;
                                                        }
                                                    };
                                                })(a.id, e, a.callbacks ? a.callbacks : []);
                                                p[a.id] = {};
                                                try {
                                                    if (a.callbacks && n(a.callbacks) && a.callbacks.length > 0)
                                                        for (var c = 0; c < a.callbacks.length; c++) {
                                                            for (var f = a.callbacks[c], h = a.params, g = f.split("/"), w = 0; w < g.length - 1; w++) {
                                                                var y = g[w];
                                                                "object" != typeof h[y] && (h[y] = {}), (h = h[y]);
                                                            }
                                                            h[g[g.length - 1]] = (function () {
                                                                var e = f;
                                                                return function (t) {
                                                                    return s.invoke(e, t);
                                                                };
                                                            })();
                                                        }
                                                    var b = l[t](s, a.params);
                                                    s.delayReturn() || s.completed() || s.complete(b);
                                                } catch (e) {
                                                    var k = "runtime_error",
                                                        C = null;
                                                    if (
                                                        ("string" == typeof e
                                                            ? (C = e)
                                                            : "object" == typeof e &&
                                                              (e && n(e) && 2 == e.length
                                                                  ? ((k = e[0]), (C = e[1]))
                                                                  : "string" == typeof e.error &&
                                                                    ((k = e.error), e.message ? ("string" == typeof e.message ? (C = e.message) : (e = e.message)) : (C = ""))),
                                                        null === C)
                                                    )
                                                        try {
                                                            void 0 === (C = JSON.stringify(e)) && (C = e.toString());
                                                        } catch (t) {
                                                            C = e.toString();
                                                        }
                                                    s.error(k, C);
                                                }
                                            }
                                        } else if (a.id && a.callback)
                                            u[a.id] && u[a.id].callbacks && u[a.id].callbacks[a.callback]
                                                ? u[a.id].callbacks[a.callback](a.params)
                                                : i("ignoring invalid callback, id:" + a.id + " (" + a.callback + ")");
                                        else if (a.id)
                                            u[a.id]
                                                ? (a.error ? (0, u[a.id].error)(a.error, a.message) : void 0 !== a.result ? (0, u[a.id].success)(a.result) : (0, u[a.id].success)(),
                                                  delete u[a.id],
                                                  delete r[a.id])
                                                : i("ignoring invalid response: " + a.id);
                                        else if (t) {
                                            var E = "__ready";
                                            t === E && d && ((d = !1), (l[E] = v)), l[t] && l[t]({ origin: e }, a.params);
                                        }
                                    };
                                !(function (e, n, r, o) {
                                    function i(t) {
                                        for (var n = 0; n < t.length; n++) if (t[n].win === e) return !0;
                                        return !1;
                                    }
                                    var a = !1;
                                    if ("*" === n) {
                                        for (var s in t) if (t.hasOwnProperty(s) && "*" !== s && "object" == typeof t[s][r] && (a = i(t[s][r]))) break;
                                    } else t["*"] && t["*"][r] && (a = i(t["*"][r])), !a && t[n] && t[n][r] && (a = i(t[n][r]));
                                    if (a) throw "A channel is already bound to the same window which overlaps with origin '" + n + "' and has scope '" + r + "'";
                                    "object" != typeof t[n] && (t[n] = {}), "object" != typeof t[n][r] && (t[n][r] = []), t[n][r].push({ win: e, handler: o });
                                })(o.window, o.origin, "string" == typeof o.scope ? o.scope : "", h);
                                var g = function (e) {
                                        return "string" == typeof o.scope && o.scope.length && (e = [o.scope, e].join("::")), e;
                                    },
                                    m = function (e, t) {
                                        if (!e) throw "postMessage called with null message";
                                        if ((i((d ? "post  " : "queue ") + " message: " + JSON.stringify(e)), t || d)) {
                                            if ("function" == typeof o.postMessageObserver)
                                                try {
                                                    o.postMessageObserver(o.origin, e);
                                                } catch (e) {
                                                    i("postMessageObserver() raised an exception: " + e.toString());
                                                }
                                            o.window.postMessage(JSON.stringify(e), o.origin);
                                        } else f.push(e);
                                    },
                                    v = function (e, t) {
                                        if ((i("ready msg received"), d)) throw "received ready message while in ready state.  help!";
                                        for (
                                            c += "ping" === t ? "-R" : "-L",
                                                w.unbind("__ready"),
                                                d = !0,
                                                i("ready msg accepted."),
                                                "ping" === t && w.notify({ method: "__ready", params: "pong" });
                                            f.length;

                                        )
                                            m(f.pop());
                                        "function" == typeof o.onReady && o.onReady(w);
                                    },
                                    w = {
                                        unbind: function (e) {
                                            if (l[e]) {
                                                if (!delete l[e]) throw "can't delete method: " + e;
                                                return !0;
                                            }
                                            return !1;
                                        },
                                        bind: function (e, t) {
                                            if (!e || "string" != typeof e) throw "'method' argument to bind must be string";
                                            if (!t || "function" != typeof t) throw "callback missing from bind params";
                                            if (l[e]) throw "method '" + e + "' is already bound!";
                                            return (l[e] = t), this;
                                        },
                                        call: function (t) {
                                            if (!t) throw "missing arguments to call function";
                                            if (!t.method || "string" != typeof t.method) throw "'method' argument to call must be string";
                                            if (!t.success || "function" != typeof t.success) throw "'success' callback missing from call";
                                            var n = {},
                                                o = [],
                                                i = [],
                                                a = function (e, t) {
                                                    if (i.indexOf(t) >= 0) throw "params cannot be a recursive data structure";
                                                    if ((i.push(t), "object" == typeof t))
                                                        for (var r in t)
                                                            if (t.hasOwnProperty(r)) {
                                                                var s = e + (e.length ? "/" : "") + r;
                                                                "function" == typeof t[r]
                                                                    ? ((n[s] = t[r]), o.push(s), delete t[r])
                                                                    : "object" == typeof t[r] && null !== t[r] && a(s, t[r]);
                                                            }
                                                };
                                            a("", t.params);
                                            var s,
                                                c,
                                                l,
                                                p = { id: e, method: g(t.method), params: t.params };
                                            o.length && (p.callbacks = o),
                                                t.timeout &&
                                                    ((s = e),
                                                    (c = t.timeout),
                                                    (l = g(t.method)),
                                                    window.setTimeout(function () {
                                                        if (u[s]) {
                                                            var e = "timeout (" + c + "ms) exceeded on method '" + l + "'";
                                                            (0, u[s].error)("timeout_error", e), delete u[s], delete r[s];
                                                        }
                                                    }, c)),
                                                (u[e] = { callbacks: n, error: t.error, success: t.success }),
                                                (r[e] = h),
                                                e++,
                                                m(p);
                                        },
                                        notify: function (e) {
                                            if (!e) throw "missing arguments to notify function";
                                            if (!e.method || "string" != typeof e.method) throw "'method' argument to notify must be string";
                                            m({ method: g(e.method), params: e.params });
                                        },
                                        destroy: function () {
                                            !(function (e, n, r) {
                                                for (var o = t[n][r], i = 0; i < o.length; i++) o[i].win === e && o.splice(i, 1);
                                                0 === t[n][r].length && delete t[n][r];
                                            })(o.window, o.origin, "string" == typeof o.scope ? o.scope : ""),
                                                window.removeEventListener
                                                    ? window.removeEventListener("message", h, !1)
                                                    : window.detachEvent && window.detachEvent("onmessage", h),
                                                (d = !1),
                                                (l = {}),
                                                (p = {}),
                                                (u = {}),
                                                (o.origin = null),
                                                (f = []),
                                                i("channel destroyed"),
                                                (c = "");
                                        }
                                    };
                                return (
                                    w.bind("__ready", v),
                                    setTimeout(function () {
                                        m({ method: g("__ready"), params: "ping" }, !0);
                                    }, 0),
                                    w
                                );
                            }
                        }
                    );
                })();
                t.Channel = n;
            }
        },
        t = {};
    function n(r) {
        var o = t[r];
        if (void 0 !== o) return o.exports;
        var i = (t[r] = { exports: {} });
        return e[r].call(i.exports, i, i.exports, n), i.exports;
    }
    (() => {
        "use strict";
        var e = n(118),
            t = n(411),
            r = function () {},
            o = "ari-convergence-container",
            i = {
                execute: function (e, t) {
                    var n = window;
                    return (
                        t.method.split(".").forEach(function (e) {
                            n = n[e];
                        }),
                        n || console.log("function ".concat(t.method, " not found.")),
                        n.apply(null, t.args)
                    );
                },
                setCartSettings: function (e, t) {
                    a.cartSettings = t;
                },
                addToCart: function (e, t) {
                    return a.addToCart(t);
                },
                onSessionTimeout: function (e, t) {
                    s.onSessionTimeout(t);
                },
                submitPickListForm: function (e, t) {
                    var n = window.document.createElement("form");
                    n.setAttribute("action", t.action), n.setAttribute("style", "display:none;"), n.setAttribute("method", t.method), n.setAttribute("target", t.target);
                    var r = document.createElement("input");
                    (r.name = t.inputName), n.appendChild(r);
                    var o = document.createElement("textarea");
                    (o.name = t.textareaName), (o.value = t.textareaValue), n.appendChild(o), window.document.body.appendChild(n), n.submit(), n.remove();
                }
            },
            a = new ((function () {
                function n(e) {
                    (this.w = e), this.extractData();
                    for (var t = o, n = 1; document.querySelector("#" + t); ) t = o + n++;
                    (this.containerId = t), this.init();
                }
                return (
                    (n.prototype.addToCart = function (e) {
                        this.windowTabAddToCart(e);
                    }),
                    (n.prototype.notify = function (e) {
                        this.channel.notify({ method: "message", params: e });
                    }),
                    (n.prototype.init = function () {
                        this.writeElement(), this.registerPostEvent();
                    }),
                    (n.prototype.windowTabAddToCart = function (e) {
                        !this.cartWind || this.cartWind.closed ? (this.cartWind = open("", "cart")) : this.cartWind.focus();
                        var t = JSON.stringify(e),
                            n = this.serializeCartData(e);
                        this.cartWind.document.createElement("p").innerHTML = "Add to cart: ".concat(t, " <br> Post: ").concat(n);
                    }),
                    (n.prototype.hiddenFrameAddCart = function (e) {}),
                    (n.prototype.createForm = function (e, n) {
                        var r = this.mapData(n),
                            o = e.createElement("form");
                        (o.action = this.cartSettings.addCartUrl),
                            this.cartSettings.paramMap.forEach(function (n) {
                                var i = e.createElement('<input type="hidden" />');
                                (i.name = n.name), (i.value = t.render(n.pattern, r)), o.appendChild(i);
                            }),
                            e.body.appendChild(o),
                            o.submit();
                    }),
                    (n.prototype.writeElement = function () {
                        var e = document.createElement("div");
                        (e.id = this.containerId), (e.style.width = "100%");
                        var t = document.createElement("iframe");
                        (t.style.width = "100%"),
                            (t.style.height = "100%"),
                            (t.style.border = "0"),
                            (t.src = this.convergenceEndpoint),
                            e.appendChild(t),
                            document.currentScript.insertAdjacentElement("afterend", e),
                            (this.container = document.querySelector("#" + this.containerId)),
                            (this.frame = this.container.querySelector("iframe"));
                    }),
                    (n.prototype.registerPostEvent = function () {
                        for (var t in ((this.channel = e.Channel.build({
                            window: this.frame.contentWindow,
                            origin: "*",
                            scope: "convergence",
                            onReady: function () {
                                console.log("ready");
                            }
                        })),
                        i))
                            this.channel.bind(t, i[t]);
                    }),
                    (n.prototype.serializeCartData = function (e) {
                        var n = this.mapData(e),
                            r = {};
                        return (
                            this.cartSettings.paramMap.forEach(function (e) {
                                r[e.name] = t.render(e.pattern, n);
                            }),
                            this.serialize(r)
                        );
                    }),
                    (n.prototype.mapData = function (e) {
                        return {
                            catalog_id: e.catalogId,
                            catalog_code: e.catalogCode,
                            catalog_name: e.catalogName,
                            part_number: e.partNumber,
                            part_description: e.partDescription,
                            price: e.price,
                            currency_code: e.currencyCode,
                            quantity: e.quantity
                        };
                    }),
                    (n.prototype.extractData = function () {
                        var e = this.w.document,
                            t = e.currentScript;
                        if (!t) {
                            var n = e.getElementsByTagName("script");
                            t = n[n.length - 1];
                        }
                        var r = e.createElement("a");
                        r.href = t.src;
                        var o = this.extractRawParams(r);
                        this.convergenceEndpoint = this.getEndpoint(r, o);
                    }),
                    (n.prototype.extractRawParams = function (e) {
                        var t = new Map();
                        if (!e.search) return t;
                        for (var n = e.search.substr(1).split("&"), r = 0; r < n.length; ++r) {
                            var o = n[r].split("=");
                            2 === o.length && t.set(decodeURIComponent(o[0]).toLowerCase(), decodeURIComponent(o[1]));
                        }
                        return t;
                    }),
                    (n.prototype.getEndpoint = function (e, t) {
                        var n = new Map(),
                            r = new Map();
                        t.forEach(function (e, t) {
                            "access_token" === t || "refresh_token" === t || "expires_in" === t ? n.set(t, e) : r.set(t, e);
                        });
                        var o = "",
                            i = r.get("id");
                        if (i) o = this.buildModelDetailRoute(i, r);
                        else if (this.isSearchRoute(r)) {
                            o = "/search";
                            var a = this.getSearchRouteParams(r);
                            a.size > 0 &&
                                a.forEach(function (e, t) {
                                    return n.set(t, e);
                                });
                        }
                        var s = "".concat(e.protocol, "//").concat(e.host, "/portal/demo");
                        return "".concat(s).concat(o, "?").concat(this.serializeMap(n));
                    }),
                    (n.prototype.buildModelDetailRoute = function (e, t) {
                        if (!e) return console.log("id is a required parameter"), "";
                        var n = t.get("catalog");
                        return n ? "/model/".concat(n, "/").concat(e) : (console.log("catalog is a required parameter"), "");
                    }),
                    (n.prototype.getSearchRouteParams = function (e) {
                        var t = new Map(),
                            n = e.get("criterion");
                        n && t.set("q", n);
                        var r = e.get("catalogs");
                        return r && t.set("catalogs", r.replace(/\s+/g, "")), t;
                    }),
                    (n.prototype.isSearchRoute = function (e) {
                        var t = e.get("route");
                        return !(!t || "search" !== t) || !!e.has("criterion") || !!e.has("catalogs");
                    }),
                    (n.prototype.serialize = function (e) {
                        var t = [];
                        for (var n in e)
                            if (e.hasOwnProperty(n)) {
                                if ("route" === n.toLowerCase()) continue;
                                t.push(encodeURIComponent(n) + "=" + encodeURIComponent(e[n]));
                            }
                        return t.join("&");
                    }),
                    (n.prototype.serializeMap = function (e) {
                        var t = [];
                        return (
                            e.forEach(function (e, n) {
                                t.push(encodeURIComponent(n) + "=" + encodeURIComponent(e));
                            }),
                            t.join("&")
                        );
                    }),
                    n
                );
            })())(window),
            s = new r();
        (s.onSessionTimeout = function () {}),
            (window.ARI = {
                PartSmart: {
                    options: s,
                    logout: function () {
                        a.notify({ type: "logout" });
                    },
                    keepAlive: function () {
                        a.notify({ type: "keepSessionAlive" });
                    },
                    displaySuccess: function (e) {
                        a.notify({ type: "displayMessage", data: { type: "success", message: e } });
                    },
                    displayError: function (e) {
                        a.notify({ type: "displayMessage", data: { type: "error", message: e } });
                    }
                }
            });
    })();
})();
