+++
title = "Tips for logging into code agents remotely"
draft = true

[taxonomies]
categories = ["cloud"]

[extra]
toc = true
+++

We've all been there once or twice. We log into Claude Code, or Codex CLI, or even AWS, which spews an URL to open in our browser to authenticate the code agent. So we dutifully do so, only to be greeted with a redirect to `localhost:WEIRDPORT`, and the page says it can't load the page.

Then we realize that it's because the client is running in Github Codespaces, or we are inside a Docker container, or some other remote environment, so `localhost` does not actually point to the machine that's running the client.

So, we dive into documentation on how to force some sort of "device auth", or "manual auth", or "out-of-band auth", so that there's a code we can copy-paste into the terminal after authenticating in the browser. Sometimes this is implemented, but it needs to be explicitly enabled. Sometimes it's automatic, but it doesn't get triggered automatically after all. Sometimes it's a lone issue in a repository that has been open for two and a half years with no response from maintainers.

In any case, it's tedious. But, fear not, there's an easier way.

Take that long URL that the browser redirected to that is in localhost, and copy the entire URL. Then, get a shell in the environment where the client is running, and use `curl` or `wget` to fetch that URL:

```sh
curl 'http://localhost:WEIRDPORT/some/long/path?with=query&parameters'
```

Remember to include the single quotes around the URL to avoid shell interpretation of special characters.

And that's it. Usually the response is a HTML mess you can ignore, but the client has received the authentication token and has logged in. Sometimes it might not continue automatically because something isn't triggering it right, but you can usually just restart the client and it will pick up the authenticated session.
