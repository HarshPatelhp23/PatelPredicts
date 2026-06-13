import { createConsumer } from "@rails/actioncable"
import ActionCable from "@rails/actioncable"
const consumer = ActionCable.createConsumer()
window._actionCableConsumer = window._actionCableConsumer || createConsumer()
export default window._actionCableConsumer
