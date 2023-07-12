from locust import HttpUser, task

class BasicUser(HttpUser):
    wait_time = between(1,3)

    @task
    def index(self)
        self.client.get("/")
