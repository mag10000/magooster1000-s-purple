console.log("You are logged in, your session token is:")
console.log((window.location.href).replace("https://mag10000.github.io/magooster1000-s-purple/logged-in","").replace("?id=",""))
const file = new File([(window.location.href).replace("https://mag10000.github.io/magooster1000-s-purple/logged-in","").replace("?id=","")], "session", {type: "text/plain",});
