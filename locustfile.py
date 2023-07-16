from locust import HttpUser, task, between


class BasicUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def index(self):
        self.client.get("/")

    @task
    def exhibitions(self):
        self.client.get("/exhibitions")

    @task
    def exhibition_detail(self):
        self.client.get("/exhibitions/the-roman-empire")

    @task
    def about(self):
        self.client.get("/about")
