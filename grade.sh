   docker build -t diagnostic-tool .
   docker run --rm diagnostic-tool help
   docker run --rm diagnostic-tool system
   docker run --rm diagnostic-tool disk
   docker run --rm diagnostic-tool bogus; echo $?     # expect 2
   docker compose run --rm diagnostic system
   ./test.sh
