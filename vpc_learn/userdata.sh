#!/bin/bash

apt update

# Get the instance ID using the instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

mkdir ~/html

touch ~/html/index.html

# Create a simple HTML file with the portfolio content and display the images
cat <<EOF > ~/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>My Portfolio</title>
  <style>
    /* Add animation and styling for the text */
    @keyframes colorChange {
      0% { color: red; }
      50% { color: green; }
      100% { color: blue; }
    }
    h1 {
      animation: colorChange 2s infinite;
    }
  </style>
</head>
<body>
  <h1>Terraform Project Server 1</h1>
  
  <h2>Instance ID: <span style="color:green">$INSTANCE_ID</span></h2>
  
  <p>VPC 2-Tier Application created using Terraform</p>
  
  <p>Python Web Server</p>

</body>
</html>
EOF

cd ~/html/

python3 -m http.server 80