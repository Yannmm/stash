export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname !== "/callback/baidupan") {
      return new Response("Not Found", { status: 404 });
    }

    const code = url.searchParams.get("code");
    const state = url.searchParams.get("state");

    if (!code || !state) {
      return new Response(
        "<html><body><p>Authorization failed — please try again from the app.</p></body></html>",
        { status: 400, headers: { "Content-Type": "text/html; charset=utf-8" } }
      );
    }

    const redirect = `nustash://oauth/baidupan?code=${encodeURIComponent(code)}&state=${encodeURIComponent(state)}`;
    return Response.redirect(redirect, 302);
  },
};
