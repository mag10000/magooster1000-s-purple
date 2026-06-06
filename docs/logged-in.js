console.log("You are logged in, your session token is:")
const searchParams = new URLSearchParams(document.URL);
console.log(searchParams.get("id"))
