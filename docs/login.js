
      // Create a button element
      const button = document.createElement('button')
      
      
      // Set the button text to 'Can you click me?'
      button.innerText = 'Can you click me?'

      button.id = 'mainButton'
      document.getElementById("mainButton").style.color = "blue";

      // Attach the "click" event to your button
      button.addEventListener('click', () => {
        // When there is a "click"
        // it shows an alert in the browser
        alert('Oh, you clicked me!')
      })

      document.body.appendChild(button)
