while true; do
  curl -s http://adaf6a50fdb5111e7a697063dee8ea6c-49855228.us-west-1.elb.amazonaws.com/productpage > /dev/null
  echo -n .;
  sleep 0.2
done