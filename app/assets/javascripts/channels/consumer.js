// app/javascript/channels/consumer.js
import { createConsumer } from "@rails/actioncable"

// This creates the WebSocket connection
const consumer = createConsumer()

export default consumer
