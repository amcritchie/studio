import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()
consumer.subscriptions.create("SessionChannel", {
  received(data) {
    if (data.type === "logout") {
      window.location.href = "/login"
    }
  }
})
