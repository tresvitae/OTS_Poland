import pygame
import random
import sys

# Initialize Pygame
pygame.init()

# Set up the display
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
pygame.display.set_caption("Catch the Ball!")

# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
BLUE = (0, 0, 255)

# Player (paddle) properties
paddle_width = 100
paddle_height = 20
paddle_x = WINDOW_WIDTH // 2 - paddle_width // 2
paddle_y = WINDOW_HEIGHT - 40
paddle_speed = 8

# Ball properties
ball_radius = 10
ball_x = random.randint(ball_radius, WINDOW_WIDTH - ball_radius)
ball_y = 0
ball_speed = 5

# Game variables
score = 0
font = pygame.font.Font(None, 36)

# Game loop
clock = pygame.time.Clock()
running = True

while running:
    # Handle events
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # Move paddle
    keys = pygame.key.get_pressed()
    if keys[pygame.K_LEFT] and paddle_x > 0:
        paddle_x -= paddle_speed
    if keys[pygame.K_RIGHT] and paddle_x < WINDOW_WIDTH - paddle_width:
        paddle_x += paddle_speed

    # Move ball
    ball_y += ball_speed

    # Check for collision with paddle
    if (ball_y + ball_radius >= paddle_y and 
        paddle_x <= ball_x <= paddle_x + paddle_width):
        score += 1
        ball_y = 0
        ball_x = random.randint(ball_radius, WINDOW_WIDTH - ball_radius)

    # Check if ball is missed
    if ball_y > WINDOW_HEIGHT:
        ball_y = 0
        ball_x = random.randint(ball_radius, WINDOW_WIDTH - ball_radius)

    # Draw everything
    screen.fill(BLACK)
    
    # Draw paddle
    pygame.draw.rect(screen, BLUE, (paddle_x, paddle_y, paddle_width, paddle_height))
    
    # Draw ball
    pygame.draw.circle(screen, RED, (int(ball_x), int(ball_y)), ball_radius)
    
    # Draw score
    score_text = font.render(f"Score: {score}", True, WHITE)
    screen.blit(score_text, (10, 10))

    # Update display
    pygame.display.flip()
    
    # Control game speed
    clock.tick(60)

# Quit game
pygame.quit()
sys.exit()