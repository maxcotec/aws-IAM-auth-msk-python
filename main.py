import argparse
import threading

import subprocess as subp


def parse_arguments():
    """ parse the arguments of the script """
    parser = argparse.ArgumentParser(description='Kafka Sub Pub')

    # Required Arguments
    required_parser = parser.add_argument_group(title='required arguments')

    required_parser.add_argument('--sub-topic', required=True, help="topic where to consume data from")
    required_parser.add_argument('--kafka-servers', help="kafka servers (comma seperated)")
    required_parser.add_argument('--pub-topic', required=True, help="topic where to publish data to")
    required_parser.add_argument('--configs', required=False,
                                 help="custom client properties to enable IAM auth enabled kafka cluster.")

    # optional
    parser.add_argument('--kafka-path', default="/app/kafka_2.12-3.4.1",
                        help="location where kafka is installed")
    parser.add_argument('--aws-region', default="eu-west-1", help="aws region")
    parser.add_argument('--debug', action='store_true', default=False,
                        help='Use debug level logging messages.')
    return parser.parse_args()


def create_cli_consumer(arguments):
    print(f"Initializing kafka consumer for servers: {arguments.kafka_servers}, topic: {arguments.sub_topic}")

    kafka_consumer_init_cmd = [
        f"{arguments.kafka_path}/bin/kafka-console-consumer.sh",
        "--topic", arguments.sub_topic,
        "--bootstrap-server", arguments.kafka_servers
    ]

    if arguments.configs:
        kafka_consumer_init_cmd = kafka_consumer_init_cmd + ["--consumer.config", arguments.configs]

    try:
        cons = subp.Popen(kafka_consumer_init_cmd, stdout=subp.PIPE, stderr=subp.PIPE)
        print("kafka consumer init done.")
        return cons
    except Exception as e:
        print(f"Error creating consumer: {e}")
        return None


def create_cli_producer(arguments):
    print(f"Initializing kafka producer for servers: {arguments.kafka_servers}")
    print(f"topic: {arguments.pub_topic}")

    kafka_producer_init_cmd = [
        f"{arguments.kafka_path}/bin/kafka-console-producer.sh",
        "--topic", arguments.pub_topic,
        "--bootstrap-server", arguments.kafka_servers
    ]

    if arguments.configs:
        kafka_producer_init_cmd = kafka_producer_init_cmd + ["--producer.config", arguments.configs]

    try:
        proc = subp.Popen(kafka_producer_init_cmd, stdin=subp.PIPE)
        print("kafka producer init done.")
        return proc
    except Exception as e:
        print(f"Error creating producer: {e}")
        return None


# Define a function to consume messages
def consume_messages(consumer, producer):
    print('Listening for new messages...')
    try:
        for line in consumer.stdout:
            rcvd_msg = line.decode().strip()
            print(f"Received: {rcvd_msg}")

            send_msg_thread = threading.Thread(target=send_message, args=(producer, rcvd_msg))
            send_msg_thread.daemon = True
            send_msg_thread.start()
    except KeyboardInterrupt:
        # If the user interrupts the program (e.g., by pressing Ctrl+C),
        # terminate the subprocess gracefully
        consumer.terminate()
        consumer.wait()

    finally:
        # Capture and print any error messages from the consumer's standard error stream
        for error_line in consumer.stderr:
            print("Error:", error_line.decode().strip())


def send_message(producer, msg):
    # Publish the received message to the producer
    try:
        print(f"Publishing message: {msg}")
        producer.stdin.write(msg.encode() + b"\n")
        producer.stdin.flush()
    except Exception as e:
        print(f"Error sending message: {e}")


def main():
    args = parse_arguments()

    # Create the producer process in a separate thread
    kafka_producer = create_cli_producer(args)

    # Create the consumer process
    kafka_consumer = create_cli_consumer(args)

    # Start the Kafka consumer thread
    consumer_thread = threading.Thread(target=consume_messages, args=(kafka_consumer, kafka_producer))
    consumer_thread.daemon = True
    consumer_thread.start()

    # Your main program logic can continue here while the consumer and producer threads are running

    # For example, you can add a loop to keep the main thread alive or perform other operations.
    while True:
        pass


if __name__ == "__main__":
    main()

