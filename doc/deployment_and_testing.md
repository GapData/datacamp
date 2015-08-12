# Deployment, testing and integration


## Deployment ##

- configure ssh keys (add to authorized keys)

	- login to server with ssh

	- add ssh/key (.ssh/id/rsa.pub) to home/deploy/.ssh/authorized/keys

- deploy to staging
   
		$ cap staging deploy   # deploy to staging server

- deploy to production

		$ cap production deploy # deploy to production server

- migration app database

 		$ cap production deploy:migrate

- migration data_database / staging_database

		$ bundle exec db/data:migrate RAILS/ENV=production

		$ bundle exec db/staging:migrate RAILS/ENV=production

- restart production server

	- from local

			$ bundle exec cap production deploy:start
			
			$ bundle exec cap production deploy:stop
			
			$ bundle exec cap production deploy:restart

	- from server

    		$ sudo sv up datanest
    		
    		$ sudo sv down datanest
    		
    		$ sudo sv restart datanest

- restart staging server

	- from local

			$ bundle exec cap production deploy:start
			
			$ bundle exec cap production deploy:stop
			
			$ bundle exec cap production deploy:restart

	- from server

			$ sudo sv up datanest/staging
			
			$ sudo sv down datanest/staging
			
			$ sudo sv restart datanest/staging


- restart delay job

		$ bundle exec rake delayed/job:restart RAILS/ENV=production
		
		$ bundle exec rake delayed/job:restart RAILS/ENV=staging

## Testing ##

- bundle exec rake
- bundle exec cucumber
