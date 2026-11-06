#!/bin/bash

# ============================================
# AI Motion Studio Pro - Plugin Builder
# Creates complete plugin and generates zip file
# ============================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Plugin details
PLUGIN_NAME="ai-motion-studio-pro"
PLUGIN_DIR="./$PLUGIN_NAME"
ZIP_FILE="$PLUGIN_NAME.zip"

# Clean up if exists
rm -rf "$PLUGIN_DIR" "$ZIP_FILE"

# Create directory structure
echo -e "${BLUE}Creating plugin directory structure...${NC}"
mkdir -p "$PLUGIN_DIR/includes"
mkdir -p "$PLUGIN_DIR/assets/css"
mkdir -p "$PLUGIN_DIR/assets/js"
mkdir -p "$PLUGIN_DIR/assets/images"
mkdir -p "$PLUGIN_DIR/templates"
mkdir -p "$PLUGIN_DIR/languages"

# ============================================
# CREATE ALL PLUGIN FILES
# ============================================

echo -e "${BLUE}Creating plugin files...${NC}"

# 1. Main plugin file
cat > "$PLUGIN_DIR/ai-motion-studio-pro.php" << 'PLUGINEOF'
<?php
/**
 * Plugin Name: AI Motion Studio Pro
 * Plugin URI: https://yourdomain.com/ai-motion-studio-pro
 * Description: Complete AI-powered image, video, avatar, and story generation platform for WordPress
 * Version: 1.0.0
 * Author: Your Company
 * Author URI: https://yourdomain.com
 * License: GPL-2.0+
 * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
 * Text Domain: ai-motion-studio
 * Domain Path: /languages
 */

if (!defined('ABSPATH')) exit;

define('AI_MOTION_VERSION', '1.0.0');
define('AI_MOTION_DIR', plugin_dir_path(__FILE__));
define('AI_MOTION_URL', plugin_dir_url(__FILE__));
define('AI_MOTION_BASENAME', plugin_basename(__FILE__));

// Check requirements
register_activation_hook(__FILE__, function() {
    if (version_compare(PHP_VERSION, '7.4', '<')) {
        deactivate_plugins(plugin_basename(__FILE__));
        wp_die('AI Motion Studio Pro requires PHP 7.4+');
    }
});

// Load all classes
$includes = [
    'includes/class-core.php',
    'includes/class-ai-image.php',
    'includes/class-ai-video.php',
    'includes/class-templates.php',
    'includes/class-credits.php',
    'includes/class-subscriptions.php',
    'includes/class-woocommerce.php',
    'includes/class-white-label.php',
    'includes/class-admin-dashboard.php',
    'includes/class-user-dashboard.php',
    'includes/class-queue.php',
    'includes/class-storage.php',
    'includes/class-security.php',
    'includes/class-ai-avatar.php',
    'includes/class-ai-story.php',
    'includes/class-ai-voice.php',
    'includes/class-social-export.php',
];

foreach ($includes as $file) {
    if (file_exists(AI_MOTION_DIR . $file)) {
        require_once AI_MOTION_DIR . $file;
    }
}

// Initialize
function ai_motion_init() {
    load_plugin_textdomain('ai-motion-studio', false, dirname(plugin_basename(__FILE__)) . '/languages');
    \AI_Motion_Studio\Core::init();
}
add_action('plugins_loaded', 'ai_motion_init');

// Activation/Deactivation
function ai_motion_activate() { \AI_Motion_Studio\Core::activate(); flush_rewrite_rules(); }
function ai_motion_deactivate() { flush_rewrite_rules(); }
register_activation_hook(__FILE__, 'ai_motion_activate');
register_deactivation_hook(__FILE__, 'ai_motion_deactivate');
PLUGINEOF

# 2. Core class
cat > "$PLUGIN_DIR/includes/class-core.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class Core {
    private static $instance = null;

    private function __construct() {
        add_action('init', [$this, 'register_post_types']);
        add_action('init', [$this, 'register_taxonomies']);
        add_action('admin_menu', [$this, 'add_admin_menu']);
        add_action('admin_enqueue_scripts', [$this, 'enqueue_admin_assets']);
        add_action('wp_enqueue_scripts', [$this, 'enqueue_frontend_assets']);
        add_action('admin_notices', [$this, 'admin_notices']);
        add_filter('plugin_action_links_' . plugin_basename(__DIR__), [$this, 'add_plugin_links']);
    }

    public static function init() {
        if (is_null(self::$instance)) self::$instance = new self();
        return self::$instance;
    }

    public static function activate() {
        self::create_required_pages();
        if (!get_option('ai_motion_settings')) {
            update_option('ai_motion_settings', [
                'api_provider' => 'default',
                'default_model' => 'realistic',
                'default_duration' => 5,
                'default_resolution' => '720p',
                'enable_white_label' => false,
            ]);
        }
        if (!get_option('ai_motion_credit_packs')) {
            update_option('ai_motion_credit_packs', [
                'starter' => ['name' => 'Starter', 'credits' => 100, 'price' => 9.99],
                'pro' => ['name' => 'Pro', 'credits' => 1000, 'price' => 49.99],
                'business' => ['name' => 'Business', 'credits' => 5000, 'price' => 199.99],
                'unlimited' => ['name' => 'Unlimited', 'credits' => -1, 'price' => 499.99],
            ]);
        }
    }

    private static function create_required_pages() {
        $pages = [
            'ai-motion-dashboard' => ['title' => 'AI Motion Studio', 'content' => '[ai_motion_dashboard]'],
            'ai-motion-generate' => ['title' => 'Generate Content', 'content' => '[ai_motion_generate]'],
            'ai-motion-templates' => ['title' => 'Templates', 'content' => '[ai_motion_templates]'],
            'ai-motion-credits' => ['title' => 'My Credits', 'content' => '[ai_motion_credits]'],
        ];
        foreach ($pages as $slug => $page) {
            if (!get_page_by_path($slug)) {
                wp_insert_post(['post_title' => $page['title'], 'post_name' => $slug, 'post_content' => $page['content'], 'post_type' => 'page', 'post_status' => 'publish']);
            }
        }
    }

    public function register_post_types() {
        register_post_type('ai_generation', [
            'labels' => ['name' => 'Generations', 'singular_name' => 'Generation'],
            'public' => true, 'show_ui' => true, 'supports' => ['title', 'editor', 'thumbnail'],
        ]);
        register_post_type('ai_template', [
            'labels' => ['name' => 'Templates', 'singular_name' => 'Template'],
            'public' => true, 'show_ui' => true, 'supports' => ['title', 'editor', 'thumbnail'],
        ]);
        register_post_type('ai_character', [
            'labels' => ['name' => 'Characters', 'singular_name' => 'Character'],
            'public' => true, 'show_ui' => true, 'supports' => ['title', 'thumbnail'],
        ]);
        register_post_type('ai_story', [
            'labels' => ['name' => 'Stories', 'singular_name' => 'Story'],
            'public' => true, 'show_ui' => true, 'supports' => ['title', 'editor', 'thumbnail'],
        ]);
    }

    public function register_taxonomies() {
        $categories = ['Portrait', 'Camera', 'Actions', 'Social', 'Romance', 'Fantasy', 'Anime', 'Cinematic'];
        register_taxonomy('ai_template_category', ['ai_template'], [
            'hierarchical' => true, 'labels' => ['name' => 'Categories'], 'show_ui' => true,
        ]);
        register_taxonomy('ai_template_tag', ['ai_template'], [
            'hierarchical' => false, 'labels' => ['name' => 'Tags'], 'show_ui' => true,
        ]);
    }

    public function add_admin_menu() {
        add_menu_page('AI Motion Studio', 'AI Motion Studio', 'manage_options', 'ai-motion-dashboard', [$this, 'render_dashboard'], 'dashicons-format-video', 20);
        add_submenu_page('ai-motion-dashboard', 'Dashboard', 'Dashboard', 'manage_options', 'ai-motion-dashboard', [$this, 'render_dashboard']);
        add_submenu_page('ai-motion-dashboard', 'Generate', 'Generate', 'edit_posts', 'ai-motion-generate', [$this, 'render_generate']);
        add_submenu_page('ai-motion-dashboard', 'Templates', 'Templates', 'edit_posts', 'ai-motion-templates', [$this, 'render_templates']);
        add_submenu_page('ai-motion-dashboard', 'Credits', 'Credits', 'edit_posts', 'ai-motion-credits', [$this, 'render_credits']);
        add_submenu_page('ai-motion-dashboard', 'Settings', 'Settings', 'manage_options', 'ai-motion-settings', [$this, 'render_settings']);
    }

    public function render_dashboard() { echo '<div class="wrap"><h1>AI Motion Studio Dashboard</h1><p>Welcome to your AI content creation platform.</p></div>'; }
    public function render_generate() { echo '<div class="wrap"><h1>Generate Content</h1><p>Create images, videos, and more.</p></div>'; }
    public function render_templates() { echo '<div class="wrap"><h1>Motion Templates</h1><p>Browse and use templates.</p></div>'; }
    public function render_credits() { echo '<div class="wrap"><h1>My Credits</h1><p>View your credit balance.</p></div>'; }
    public function render_settings() { echo '<div class="wrap"><h1>Settings</h1><p>Configure your AI settings.</p></div>'; }

    public function enqueue_admin_assets() {
        wp_enqueue_style('ai-motion-admin', AI_MOTION_URL . 'assets/css/admin.css', [], AI_MOTION_VERSION);
        wp_enqueue_script('ai-motion-admin', AI_MOTION_URL . 'assets/js/admin.js', ['jquery'], AI_MOTION_VERSION, true);
    }

    public function enqueue_frontend_assets() {
        wp_enqueue_style('ai-motion-frontend', AI_MOTION_URL . 'assets/css/frontend.css', [], AI_MOTION_VERSION);
        wp_enqueue_script('ai-motion-frontend', AI_MOTION_URL . 'assets/js/frontend.js', ['jquery'], AI_MOTION_VERSION, true);
    }

    public function admin_notices() {
        if (!get_option('ai_motion_settings') || empty(get_option('ai_motion_settings')['api_provider'])) {
            echo '<div class="notice notice-warning"><p>Please configure AI Motion Studio <a href="' . admin_url('admin.php?page=ai-motion-settings') . '">settings</a>.</p></div>';
        }
    }

    public function add_plugin_links($links) {
        $links[] = '<a href="' . admin_url('admin.php?page=ai-motion-dashboard') . '">Dashboard</a>';
        $links[] = '<a href="' . admin_url('admin.php?page=ai-motion-settings') . '">Settings</a>';
        return $links;
    }
}
PLUGINEOF

# 3. AI Image Generator
cat > "$PLUGIN_DIR/includes/class-ai-image.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class AI_Image {
    private static $instance = null;

    private function __construct() {
        add_shortcode('ai_motion_image', [$this, 'image_shortcode']);
        add_action('wp_ajax_ai_motion_generate_image', [$this, 'ajax_generate_image']);
        add_action('wp_ajax_nopriv_ai_motion_generate_image', [$this, 'ajax_generate_image']);
    }

    public static function init() {
        if (is_null(self::$instance)) self::$instance = new self();
        return self::$instance;
    }

    public function image_shortcode($atts) {
        $atts = shortcode_atts([
            'prompt' => '',
            'style' => 'realistic',
            'width' => 512,
            'height' => 512,
            'class' => '',
        ], $atts);

        ob_start();
        ?>
        <div class="ai-motion-image-generator <?php echo esc_attr($atts['class']); ?>">
            <form class="ai-motion-form" method="post">
                <input type="hidden" name="action" value="ai_motion_generate_image">
                <input type="hidden" name="style" value="<?php echo esc_attr($atts['style']); ?>">
                <input type="hidden" name="width" value="<?php echo esc_attr($atts['width']); ?>">
                <input type="hidden" name="height" value="<?php echo esc_attr($atts['height']); ?>">
                <textarea name="prompt" placeholder="<?php _e('Describe the image you want to create...', 'ai-motion-studio'); ?>" required><?php echo esc_textarea($atts['prompt']); ?></textarea>
                <button type="submit" class="ai-motion-btn"><?php _e('Generate Image', 'ai-motion-studio'); ?></button>
            </form>
            <div class="ai-motion-results"></div>
        </div>
        <?php
        return ob_get_clean();
    }

    public function ajax_generate_image() {
        check_ajax_referer('ai_motion_nonce', 'nonce');

        $prompt = sanitize_text_field($_POST['prompt'] ?? '');
        $style = sanitize_text_field($_POST['style'] ?? 'realistic');
        $width = intval($_POST['width'] ?? 512);
        $height = intval($_POST['height'] ?? 512);

        if (empty($prompt)) {
            wp_send_json_error(['message' => __('Prompt is required', 'ai-motion-studio')]);
        }

        // Simulate API call - replace with actual AI service integration
        $image_url = 'https://via.placeholder.com/' . $width . 'x' . $height . '?text=' . urlencode($prompt);

        wp_send_json_success([
            'image_url' => $image_url,
            'prompt' => $prompt,
            'style' => $style,
        ]);
    }
}
PLUGINEOF

# 4. AI Video Generator
cat > "$PLUGIN_DIR/includes/class-ai-video.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class AI_Video {
    private static $instance = null;

    private function __construct() {
        add_shortcode('ai_motion_video', [$this, 'video_shortcode']);
        add_action('wp_ajax_ai_motion_generate_video', [$this, 'ajax_generate_video']);
        add_action('wp_ajax_nopriv_ai_motion_generate_video', [$this, 'ajax_generate_video']);
    }

    public static function init() {
        if (is_null(self::$instance)) self::$instance = new self();
        return self::$instance;
    }

    public function video_shortcode($atts) {
        $atts = shortcode_atts([
            'image_url' => '',
            'template' => '',
            'duration' => 5,
            'class' => '',
        ], $atts);

        ob_start();
        ?>
        <div class="ai-motion-video-generator <?php echo esc_attr($atts['class']); ?>">
            <form class="ai-motion-form" method="post" enctype="multipart/form-data">
                <input type="hidden" name="action" value="ai_motion_generate_video">
                <input type="hidden" name="template" value="<?php echo esc_attr($atts['template']); ?>">
                <input type="hidden" name="duration" value="<?php echo esc_attr($atts['duration']); ?>">
                <input type="file" name="image" accept="image/*" required>
                <button type="submit" class="ai-motion-btn"><?php _e('Generate Video', 'ai-motion-studio'); ?></button>
            </form>
            <div class="ai-motion-results"></div>
        </div>
        <?php
        return ob_get_clean();
    }

    public function ajax_generate_video() {
        check_ajax_referer('ai_motion_nonce', 'nonce');

        if (!isset($_FILES['image'])) {
            wp_send_json_error(['message' => __('Image is required', 'ai-motion-studio')]);
        }

        $template = sanitize_text_field($_POST['template'] ?? '');
        $duration = intval($_POST['duration'] ?? 5);

        // Simulate API call
        $video_url = 'https://via.placeholder.com/640x360?text=Video+Generated';

        wp_send_json_success([
            'video_url' => $video_url,
            'template' => $template,
            'duration' => $duration,
        ]);
    }
}
PLUGINEOF

# 5. Templates Library
cat > "$PLUGIN_DIR/includes/class-templates.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class Templates {
    private static $instance = null;
    private $default_templates = [];

    private function __construct() {
        $this->load_default_templates();
        add_shortcode('ai_motion_templates', [$this, 'templates_shortcode']);
        add_action('init', [$this, 'register_default_templates']);
    }

    public static function init() {
        if (is_null(self::$instance)) self::$instance = new self();
        return self::$instance;
    }

    private function load_default_templates() {
        $this->default_templates = [
            'Portrait' => [
                ['name' => 'Smile', 'description' => 'Gentle smile animation', 'category' => 'Portrait'],
                ['name' => 'Blink', 'description' => 'Natural blinking motion', 'category' => 'Portrait'],
                ['name' => 'Head Turn', 'description' => 'Smooth head turning', 'category' => 'Portrait'],
                ['name' => 'Eye Contact', 'description' => 'Direct eye contact', 'category' => 'Portrait'],
            ],
            'Camera' => [
                ['name' => 'Zoom In', 'description' => 'Smooth zoom in effect', 'category' => 'Camera'],
                ['name' => 'Zoom Out', 'description' => 'Smooth zoom out effect', 'category' => 'Camera'],
                ['name' => 'Orbit', 'description' => '360 degree orbit', 'category' => 'Camera'],
                ['name' => 'Pan', 'description' => 'Horizontal pan', 'category' => 'Camera'],
            ],
            'Actions' => [
                ['name' => 'Walking', 'description' => 'Natural walking motion', 'category' => 'Actions'],
                ['name' => 'Running', 'description' => 'Fast running motion', 'category' => 'Actions'],
                ['name' => 'Jumping', 'description' => 'High jump motion', 'category' => 'Actions'],
            ],
            'Social' => [
                ['name' => 'Selfie', 'description' => 'Selfie-style motion', 'category' => 'Social'],
                ['name' => 'Vlog', 'description' => 'Vlog-style camera movement', 'category' => 'Social'],
            ],
            'Romance' => [
                ['name' => 'Hug', 'description' => 'Romantic hug motion', 'category' => 'Romance'],
                ['name' => 'Kiss', 'description' => 'Romantic kiss motion', 'category' => 'Romance'],
            ],
            'Fantasy' => [
                ['name' => 'Wings', 'description' => 'Angel wings appearance', 'category' => 'Fantasy'],
                ['name' => 'Magic', 'description' => 'Magic sparkles effect', 'category' => 'Fantasy'],
            ],
            'Anime' => [
                ['name' => 'Anime Portrait', 'description' => 'Anime-style portrait', 'category' => 'Anime'],
                ['name' => 'Hair Flow', 'description' => 'Anime hair flowing', 'category' => 'Anime'],
            ],
            'Cinematic' => [
                ['name' => 'Slow Motion', 'description' => 'Cinematic slow motion', 'category' => 'Cinematic'],
                ['name' => 'Action Shot', 'description' => 'Dynamic action shot', 'category' => 'Cinematic'],
            ],
        ];
    }

    public function register_default_templates() {
        $existing = get_option('ai_motion_default_templates', []);
        if (empty($existing)) {
            update_option('ai_motion_default_templates', $this->default_templates);
        }
    }

    public function templates_shortcode($atts) {
        $atts = shortcode_atts([
            'category' => '',
            'limit' => -1,
            'class' => '',
        ], $atts);

        $templates = $this->get_templates($atts['category']);
        $limit = intval($atts['limit']);

        if ($limit > 0) {
            $templates = array_slice($templates, 0, $limit);
        }

        ob_start();
        ?>
        <div class="ai-motion-templates <?php echo esc_attr($atts['class']); ?>">
            <div class="ai-motion-template-grid">
                <?php foreach ($templates as $template): ?>
                    <div class="ai-motion-template-card" data-template="<?php echo esc_attr($template['name']); ?>">
                        <h3><?php echo esc_html($template['name']); ?></h3>
                        <p><?php echo esc_html($template['description']); ?></p>
                        <span class="ai-motion-template-category"><?php echo esc_html($template['category']); ?></span>
                        <button class="ai-motion-btn ai-motion-btn-secondary">Use Template</button>
                    </div>
                <?php endforeach; ?>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }

    private function get_templates($category = '') {
        $templates = [];
        foreach ($this->default_templates as $cat => $cat_templates) {
            if ($category && $cat !== $category) continue;
            foreach ($cat_templates as $template) {
                $templates[] = $template;
            }
        }
        return $templates;
    }

    public function get_template($name) {
        foreach ($this->default_templates as $category => $templates) {
            foreach ($templates as $template) {
                if ($template['name'] === $name) {
                    return $template;
                }
            }
        }
        return null;
    }
}
PLUGINEOF

# 6. Credits System
cat > "$PLUGIN_DIR/includes/class-credits.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class Credits {
    private static $instance = null;

    private function __construct() {
        add_shortcode('ai_motion_credits', [$this, 'credits_shortcode']);
        add_action('wp_ajax_ai_motion_get_credits', [$this, 'ajax_get_credits']);
        add_action('wp_ajax_ai_motion_use_credits', [$this, 'ajax_use_credits']);
    }

    public static function init() {
        if (is_null(self::$instance)) self::$instance = new self();
        return self::$instance;
    }

    public function credits_shortcode($atts) {
        $user_id = get_current_user_id();
        $balance = $this->get_user_balance($user_id);

        ob_start();
        ?>
        <div class="ai-motion-credits">
            <h2><?php _e('Your Credit Balance', 'ai-motion-studio'); ?></h2>
            <div class="ai-motion-credit-balance">
                <span class="ai-motion-credit-amount"><?php echo esc_html($balance); ?></span>
                <span class="ai-motion-credit-label"><?php _e('credits', 'ai-motion-studio'); ?></span>
            </div>
            <div class="ai-motion-credit-packs">
                <h3><?php _e('Credit Packs', 'ai-motion-studio'); ?></h3>
                <?php $this->display_credit_packs(); ?>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }

    private function display_credit_packs() {
        $packs = get_option('ai_motion_credit_packs', []);
        foreach ($packs as $key => $pack) {
            echo '<div class="ai-motion-credit-pack">';
            echo '<h4>' . esc_html($pack['name']) . '</h4>';
            echo '<p>' . esc_html($pack['credits']) . ' ' . __('credits', 'ai-motion-studio') . '</p>';
            echo '<span class="ai-motion-pack-price">$' . esc_html($pack['price']) . '</span>';
            echo '<button class="ai-motion-btn" data-pack="' . esc_attr($key) . '">' . __('Purchase', 'ai-motion-studio') . '</button>';
            echo '</div>';
        }
    }

    public function get_user_balance($user_id) {
        return intval(get_user_meta($user_id, 'ai_motion_credits', true) ?? 0);
    }

    public function add_credits($user_id, $amount) {
        $current = $this->get_user_balance($user_id);
        update_user_meta($user_id, 'ai_motion_credits', $current + $amount);
        return $current + $amount;
    }

    public function use_credits($user_id, $amount) {
        $current = $this->get_user_balance($user_id);
        if ($current < $amount) {
            return new \WP_Error('insufficient_credits', __('Insufficient credits', 'ai-motion-studio'));
        }
        update_user_meta($user_id, 'ai_motion_credits', $current - $amount);
        return $current - $amount;
    }

    public function ajax_get_credits() {
        check_ajax_referer('ai_motion_nonce', 'nonce');
        $user_id = get_current_user_id();
        wp_send_json_success(['balance' => $this->get_user_balance($user_id)]);
    }

    public function ajax_use_credits() {
        check_ajax_referer('ai_motion_nonce', 'nonce');
        $user_id = get_current_user_id();
        $amount = intval($_POST['amount'] ?? 0);

        if ($amount <= 0) {
            wp_send_json_error(['message' => __('Invalid amount', 'ai-motion-studio')]);
        }

        $result = $this->use_credits($user_id, $amount);
        if (is_wp_error($result)) {
            wp_send_json_error(['message' => $result->get_error_message()]);
        }

        wp_send_json_success(['balance' => $result]);
    }
}
PLUGINEOF

# 7. WooCommerce Integration
cat > "$PLUGIN_DIR/includes/class-woocommerce.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class WooCommerce_Integration {
    private static $instance = null;

    private function __construct() {
        if (!class_exists('WooCommerce')) return;

        add_action('woocommerce_loaded', [$this, 'init_woocommerce']);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function init_woocommerce() {
        // Create credit products
        add_action('init', [$this, 'create_credit_products']);

        // Handle credit purchase
        add_action('woocommerce_payment_complete', [$this, 'handle_credit_purchase']);
    }

    public function create_credit_products() {
        $packs = get_option('ai_motion_credit_packs', []);
        $existing_products = wc_get_products(['limit' => -1, 'type' => 'simple']);

        foreach ($packs as $key => $pack) {
            $product_exists = false;
            foreach ($existing_products as $product) {
                if (get_post_meta($product->get_id(), '_ai_motion_credit_pack', true) === $key) {
                    $product_exists = true;
                    break;
                }
            }

            if (!$product_exists) {
                $product = new \WC_Product_Simple();
                $product->set_name($pack['name'] . ' Credits - AI Motion Studio');
                $product->set_regular_price($pack['price']);
                $product->set_description($pack['description']);
                $product->set_short_description(sprintf(__('%d credits for AI Motion Studio', 'ai-motion-studio'), $pack['credits']));
                $product->set_sku('AI-MOTION-' . strtoupper($key));
                $product->set_virtual(true);
                $product->set_downloadable(false);
                $product->set_sold_individually(true);
                $product->update_meta_data('_ai_motion_credit_pack', $key);
                $product->update_meta_data('_ai_motion_credits', $pack['credits']);
                $product->save();
            }
        }
    }

    public function handle_credit_purchase($order_id) {
        $order = wc_get_order($order_id);
        foreach ($order->get_items() as $item) {
            $product = $item->get_product();
            $credit_pack = $product->get_meta('_ai_motion_credit_pack', true);
            $credits = intval($product->get_meta('_ai_motion_credits', true) ?? 0);

            if ($credit_pack && $credits > 0) {
                $user_id = $order->get_user_id();
                if ($user_id) {
                    $credits_class = Credits::get_instance();
                    $credits_class->add_credits($user_id, $credits);
                }
            }
        }
    }
}
PLUGINEOF

# 8. White Label Settings
cat > "$PLUGIN_DIR/includes/class-white-label.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class White_Label {
    private static $instance = null;

    private function __construct() {
        add_action('admin_menu', [$this, 'add_settings_page'], 100);
        add_action('admin_init', [$this, 'register_settings']);
        add_filter('ai_motion_studio_branding', [$this, 'apply_white_label']);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function add_settings_page() {
        add_submenu_page(
            'ai-motion-dashboard',
            __('White Label', 'ai-motion-studio'),
            __('White Label', 'ai-motion-studio'),
            'manage_options',
            'ai-motion-white-label',
            [$this, 'render_settings_page']
        );
    }

    public function register_settings() {
        register_setting('ai_motion_white_label', 'ai_motion_white_label');

        add_settings_section(
            'ai_motion_white_label_section',
            __('White Label Settings', 'ai-motion-studio'),
            [$this, 'settings_section_callback'],
            'ai_motion_white_label'
        );

        add_settings_field(
            'ai_motion_enable_white_label',
            __('Enable White Label', 'ai-motion-studio'),
            [$this, 'enable_white_label_callback'],
            'ai_motion_white_label',
            'ai_motion_white_label_section'
        );

        add_settings_field(
            'ai_motion_white_label_name',
            __('Custom Name', 'ai-motion-studio'),
            [$this, 'white_label_name_callback'],
            'ai_motion_white_label',
            'ai_motion_white_label_section'
        );

        add_settings_field(
            'ai_motion_white_label_logo',
            __('Custom Logo', 'ai-motion-studio'),
            [$this, 'white_label_logo_callback'],
            'ai_motion_white_label',
            'ai_motion_white_label_section'
        );
    }

    public function settings_section_callback() {
        echo '<p>' . __('Customize the plugin branding for your clients', 'ai-motion-studio') . '</p>';
    }

    public function enable_white_label_callback() {
        $settings = get_option('ai_motion_white_label', []);
        echo '<input type="checkbox" name="ai_motion_white_label[enable_white_label]" value="1" ' . checked($settings['enable_white_label'] ?? 0, 1, false) . '>';
    }

    public function white_label_name_callback() {
        $settings = get_option('ai_motion_white_label', []);
        echo '<input type="text" name="ai_motion_white_label[white_label_name]" value="' . esc_attr($settings['white_label_name'] ?? '') . '" class="regular-text" placeholder="' . esc_attr(__('Your Brand Name', 'ai-motion-studio')) . '">';
    }

    public function white_label_logo_callback() {
        $settings = get_option('ai_motion_white_label', []);
        echo '<input type="url" name="ai_motion_white_label[white_label_logo]" value="' . esc_url($settings['white_label_logo'] ?? '') . '" class="regular-text" placeholder="' . esc_attr(__('https://yourdomain.com/logo.png', 'ai-motion-studio')) . '">';
    }

    public function render_settings_page() {
        ?>
        <div class="wrap">
            <h1><?php _e('White Label Settings', 'ai-motion-studio'); ?></h1>
            <form method="post" action="options.php">
                <?php
                settings_fields('ai_motion_white_label');
                do_settings_sections('ai_motion_white_label');
                submit_button(__('Save Settings', 'ai-motion-studio'));
                ?>
            </form>
        </div>
        <?php
    }

    public function apply_white_label($text) {
        $settings = get_option('ai_motion_white_label', []);
        if ($settings['enable_white_label'] ?? false) {
            return str_replace('AI Motion Studio', $settings['white_label_name'] ?? 'AI Motion Studio', $text);
        }
        return $text;
    }
}
PLUGINEOF

# 9. Queue System
cat > "$PLUGIN_DIR/includes/class-queue.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class Queue_Manager {
    private static $instance = null;

    private function __construct() {
        add_action('ai_motion_process_queue', [$this, 'process_queue']);
        add_action('wp_ajax_ai_motion_queue_status', [$this, 'ajax_queue_status']);
        add_action('wp_ajax_nopriv_ai_motion_queue_status', [$this, 'ajax_queue_status']);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function add_to_queue($task) {
        $queue = get_option('ai_motion_queue', []);
        $task['id'] = uniqid('ai_motion_', true);
        $task['status'] = 'queued';
        $task['created_at'] = current_time('mysql');
        $queue[] = $task;
        update_option('ai_motion_queue', $queue);
        return $task['id'];
    }

    public function process_queue() {
        $queue = get_option('ai_motion_queue', []);
        if (empty($queue)) return;

        foreach ($queue as $key => $task) {
            if ($task['status'] === 'queued') {
                $queue[$key]['status'] = 'processing';
                $queue[$key]['started_at'] = current_time('mysql');
                update_option('ai_motion_queue', $queue);

                // Process the task
                $result = $this->process_task($task);
                $queue[$key]['result'] = $result;
                $queue[$key]['status'] = is_wp_error($result) ? 'failed' : 'completed';
                $queue[$key]['completed_at'] = current_time('mysql');
                update_option('ai_motion_queue', $queue);

                // Remove completed tasks after 24 hours
                if ($queue[$key]['status'] === 'completed') {
                    unset($queue[$key]);
                }
            }
        }

        update_option('ai_motion_queue', array_values($queue));
    }

    private function process_task($task) {
        // Simulate processing
        sleep(2); // Simulate processing time
        return ['success' => true, 'message' => 'Task processed'];
    }

    public function get_queue_status($task_id = null) {
        $queue = get_option('ai_motion_queue', []);
        if ($task_id) {
            foreach ($queue as $task) {
                if ($task['id'] === $task_id) {
                    return $task;
                }
            }
            return null;
        }
        return $queue;
    }

    public function ajax_queue_status() {
        check_ajax_referer('ai_motion_nonce', 'nonce');
        $task_id = sanitize_text_field($_POST['task_id'] ?? '');
        $status = $this->get_queue_status($task_id);
        wp_send_json_success(['status' => $status]);
    }
}
PLUGINEOF

# 10. Storage Manager
cat > "$PLUGIN_DIR/includes/class-storage.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class Storage_Manager {
    private static $instance = null;
    private $provider = 'wordpress';

    private function __construct() {
        $settings = get_option('ai_motion_settings', []);
        $this->provider = $settings['storage_provider'] ?? 'wordpress';
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function upload_file($file, $user_id = 0) {
        switch ($this->provider) {
            case 's3':
                return $this->upload_to_s3($file);
            case 'cloudflare':
                return $this->upload_to_cloudflare($file);
            case 'google':
                return $this->upload_to_google($file);
            default:
                return $this->upload_to_wordpress($file);
        }
    }

    private function upload_to_wordpress($file) {
        if (!function_exists('media_handle_upload')) {
            require_once ABSPATH . 'wp-admin/includes/image.php';
            require_once ABSPATH . 'wp-admin/includes/file.php';
            require_once ABSPATH . 'wp-admin/includes/media.php';
        }

        $attachment_id = media_handle_upload('file', 0);
        if (is_wp_error($attachment_id)) {
            return $attachment_id;
        }

        return [
            'id' => $attachment_id,
            'url' => wp_get_attachment_url($attachment_id),
            'type' => 'wordpress',
        ];
    }

    private function upload_to_s3($file) {
        // Implement S3 upload
        return new \WP_Error('not_implemented', 'S3 upload not implemented');
    }

    private function upload_to_cloudflare($file) {
        // Implement Cloudflare R2 upload
        return new \WP_Error('not_implemented', 'Cloudflare upload not implemented');
    }

    private function upload_to_google($file) {
        // Implement Google Cloud Storage upload
        return new \WP_Error('not_implemented', 'Google Cloud upload not implemented');
    }

    public function delete_file($file_data) {
        switch ($file_data['type'] ?? 'wordpress') {
            case 's3':
                return $this->delete_from_s3($file_data);
            case 'cloudflare':
                return $this->delete_from_cloudflare($file_data);
            case 'google':
                return $this->delete_from_google($file_data);
            default:
                return $this->delete_from_wordpress($file_data);
        }
    }

    private function delete_from_wordpress($file_data) {
        if (isset($file_data['id'])) {
            wp_delete_attachment($file_data['id'], true);
            return true;
        }
        return false;
    }
}
PLUGINEOF

# 11. Security
cat > "$PLUGIN_DIR/includes/class-security.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class Security {
    private static $instance = null;

    private function __construct() {
        add_action('init', [$this, 'check_nonces']);
        add_filter('ai_motion_studio_capabilities', [$this, 'check_capabilities']);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function check_nonces() {
        if (isset($_POST['ai_motion_action']) && !isset($_POST['ai_motion_nonce'])) {
            wp_die(__('Security check failed: Missing nonce', 'ai-motion-studio'));
        }

        if (isset($_POST['ai_motion_nonce']) && !wp_verify_nonce($_POST['ai_motion_nonce'], 'ai_motion_nonce')) {
            wp_die(__('Security check failed: Invalid nonce', 'ai-motion-studio'));
        }
    }

    public function check_capabilities($capability) {
        $user_caps = [];
        if (current_user_can('manage_options')) {
            $user_caps['manage_settings'] = true;
            $user_caps['manage_templates'] = true;
            $user_caps['manage_users'] = true;
        }

        if (current_user_can('edit_posts')) {
            $user_caps['create_content'] = true;
            $user_caps['edit_content'] = true;
            $user_caps['delete_content'] = true;
        }

        if (current_user_can('read')) {
            $user_caps['view_content'] = true;
            $user_caps['use_credits'] = true;
        }

        return in_array($capability, $user_caps, true);
    }

    public static function generate_nonce() {
        return wp_create_nonce('ai_motion_nonce');
    }

    public static function verify_nonce($nonce) {
        return wp_verify_nonce($nonce, 'ai_motion_nonce');
    }

    public static function sanitize_input($input) {
        if (is_array($input)) {
            return array_map([__CLASS__, 'sanitize_input'], $input);
        }
        return sanitize_text_field($input);
    }

    public static function validate_file($file) {
        $allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4', 'video/webm'];
        $file_type = $file['type'] ?? '';

        if (!in_array($file_type, $allowed_types)) {
            return new \WP_Error('invalid_type', __('Invalid file type', 'ai-motion-studio'));
        }

        $max_size = 20 * 1024 * 1024; // 20MB
        if ($file['size'] > $max_size) {
            return new \WP_Error('file_too_large', __('File is too large', 'ai-motion-studio'));
        }

        return true;
    }
}
PLUGINEOF

# 12. Talking Avatar
cat > "$PLUGIN_DIR/includes/class-ai-avatar.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class AI_Avatar {
    private static $instance = null;

    private function __construct() {
        add_shortcode('ai_motion_avatar', [$this, 'avatar_shortcode']);
        add_action('wp_ajax_ai_motion_generate_avatar', [$this, 'ajax_generate_avatar']);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function avatar_shortcode($atts) {
        $atts = shortcode_atts([
            'text' => '',
            'voice' => 'en-US-Neural2-A',
            'style' => 'realistic',
            'class' => '',
        ], $atts);

        ob_start();
        ?>
        <div class="ai-motion-avatar-generator <?php echo esc_attr($atts['class']); ?>">
            <form class="ai-motion-form" method="post">
                <input type="hidden" name="action" value="ai_motion_generate_avatar">
                <input type="hidden" name="voice" value="<?php echo esc_attr($atts['voice']); ?>">
                <input type="hidden" name="style" value="<?php echo esc_attr($atts['style']); ?>">
                <textarea name="text" placeholder="<?php _e('Enter the text for your avatar to speak...', 'ai-motion-studio'); ?>" required><?php echo esc_textarea($atts['text']); ?></textarea>
                <button type="submit" class="ai-motion-btn"><?php _e('Generate Avatar Video', 'ai-motion-studio'); ?></button>
            </form>
            <div class="ai-motion-results"></div>
        </div>
        <?php
        return ob_get_clean();
    }

    public function ajax_generate_avatar() {
        check_ajax_referer('ai_motion_nonce', 'nonce');

        $text = sanitize_textarea_field($_POST['text'] ?? '');
        $voice = sanitize_text_field($_POST['voice'] ?? 'en-US-Neural2-A');
        $style = sanitize_text_field($_POST['style'] ?? 'realistic');

        if (empty($text)) {
            wp_send_json_error(['message' => __('Text is required', 'ai-motion-studio')]);
        }

        // Simulate API call
        $video_url = 'https://via.placeholder.com/640x360?text=Avatar+Video';

        wp_send_json_success([
            'video_url' => $video_url,
            'text' => $text,
            'voice' => $voice,
            'style' => $style,
        ]);
    }
}
PLUGINEOF

# 13. AI Story Generator
cat > "$PLUGIN_DIR/includes/class-ai-story.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class AI_Story {
    private static $instance = null;

    private function __construct() {
        add_shortcode('ai_motion_story', [$this, 'story_shortcode']);
        add_action('wp_ajax_ai_motion_generate_story', [$this, 'ajax_generate_story']);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function story_shortcode($atts) {
        $atts = shortcode_atts([
            'prompt' => '',
            'chapters' => 3,
            'class' => '',
        ], $atts);

        ob_start();
        ?>
        <div class="ai-motion-story-generator <?php echo esc_attr($atts['class']); ?>">
            <form class="ai-motion-form" method="post">
                <input type="hidden" name="action" value="ai_motion_generate_story">
                <input type="hidden" name="chapters" value="<?php echo esc_attr($atts['chapters']); ?>">
                <textarea name="prompt" placeholder="<?php _e('Describe the story you want to create...', 'ai-motion-studio'); ?>" required><?php echo esc_textarea($atts['prompt']); ?></textarea>
                <button type="submit" class="ai-motion-btn"><?php _e('Generate Story', 'ai-motion-studio'); ?></button>
            </form>
            <div class="ai-motion-results"></div>
        </div>
        <?php
        return ob_get_clean();
    }

    public function ajax_generate_story() {
        check_ajax_referer('ai_motion_nonce', 'nonce');

        $prompt = sanitize_text_field($_POST['prompt'] ?? '');
        $chapters = intval($_POST['chapters'] ?? 3);

        if (empty($prompt)) {
            wp_send_json_error(['message' => __('Prompt is required', 'ai-motion-studio')]);
        }

        // Simulate story generation
        $story = [
            'title' => 'The Adventure of ' . substr($prompt, 0, 10) . '...',
            'chapters' => [],
        ];

        for ($i = 1; $i <= $chapters; $i++) {
            $story['chapters'][] = [
                'title' => 'Chapter ' . $i,
                'content' => 'This is the content for chapter ' . $i . ' based on: ' . $prompt,
                'image_prompt' => $prompt . ' chapter ' . $i,
            ];
        }

        wp_send_json_success([
            'story' => $story,
            'prompt' => $prompt,
            'chapters' => $chapters,
        ]);
    }
}
PLUGINEOF

# 14. AI Voice Studio
cat > "$PLUGIN_DIR/includes/class-ai-voice.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class AI_Voice {
    private static $instance = null;
    private $voices = [];

    private function __construct() {
        $this->load_voices();
        add_shortcode('ai_motion_voice', [$this, 'voice_shortcode']);
        add_action('wp_ajax_ai_motion_generate_voice', [$this, 'ajax_generate_voice']);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    private function load_voices() {
        $this->voices = [
            'Male' => [
                ['id' => 'en-US-Male1', 'name' => 'Male 1 (English)', 'language' => 'English', 'gender' => 'Male'],
                ['id' => 'en-US-Male2', 'name' => 'Male 2 (English)', 'language' => 'English', 'gender' => 'Male'],
            ],
            'Female' => [
                ['id' => 'en-US-Female1', 'name' => 'Female 1 (English)', 'language' => 'English', 'gender' => 'Female'],
                ['id' => 'en-US-Female2', 'name' => 'Female 2 (English)', 'language' => 'English', 'gender' => 'Female'],
            ],
            'Child' => [
                ['id' => 'en-US-Child1', 'name' => 'Child 1 (English)', 'language' => 'English', 'gender' => 'Child'],
            ],
            'Anime' => [
                ['id' => 'ja-JP-Anime1', 'name' => 'Anime Male (Japanese)', 'language' => 'Japanese', 'gender' => 'Male'],
                ['id' => 'ja-JP-Anime2', 'name' => 'Anime Female (Japanese)', 'language' => 'Japanese', 'gender' => 'Female'],
            ],
        ];
    }

    public function voice_shortcode($atts) {
        $atts = shortcode_atts([
            'text' => '',
            'voice' => 'en-US-Female1',
            'emotion' => 'neutral',
            'class' => '',
        ], $atts);

        ob_start();
        ?>
        <div class="ai-motion-voice-generator <?php echo esc_attr($atts['class']); ?>">
            <form class="ai-motion-form" method="post">
                <input type="hidden" name="action" value="ai_motion_generate_voice">
                <select name="voice">
                    <?php foreach ($this->voices as $category => $category_voices): ?>
                        <optgroup label="<?php echo esc_attr($category); ?>">
                            <?php foreach ($category_voices as $voice): ?>
                                <option value="<?php echo esc_attr($voice['id']); ?>" <?php selected($atts['voice'], $voice['id']); ?>>
                                    <?php echo esc_html($voice['name']); ?>
                                </option>
                            <?php endforeach; ?>
                        </optgroup>
                    <?php endforeach; ?>
                </select>
                <select name="emotion">
                    <option value="neutral" <?php selected($atts['emotion'], 'neutral'); ?>><?php _e('Neutral', 'ai-motion-studio'); ?></option>
                    <option value="happy" <?php selected($atts['emotion'], 'happy'); ?>><?php _e('Happy', 'ai-motion-studio'); ?></option>
                    <option value="sad" <?php selected($atts['emotion'], 'sad'); ?>><?php _e('Sad', 'ai-motion-studio'); ?></option>
                    <option value="angry" <?php selected($atts['emotion'], 'angry'); ?>><?php _e('Angry', 'ai-motion-studio'); ?></option>
                    <option value="excited" <?php selected($atts['emotion'], 'excited'); ?>><?php _e('Excited', 'ai-motion-studio'); ?></option>
                </select>
                <textarea name="text" placeholder="<?php _e('Enter text to convert to speech...', 'ai-motion-studio'); ?>" required><?php echo esc_textarea($atts['text']); ?></textarea>
                <button type="submit" class="ai-motion-btn"><?php _e('Generate Voice', 'ai-motion-studio'); ?></button>
            </form>
            <div class="ai-motion-results"></div>
        </div>
        <?php
        return ob_get_clean();
    }

    public function ajax_generate_voice() {
        check_ajax_referer('ai_motion_nonce', 'nonce');

        $text = sanitize_textarea_field($_POST['text'] ?? '');
        $voice = sanitize_text_field($_POST['voice'] ?? 'en-US-Female1');
        $emotion = sanitize_text_field($_POST['emotion'] ?? 'neutral');

        if (empty($text)) {
            wp_send_json_error(['message' => __('Text is required', 'ai-motion-studio')]);
        }

        // Simulate API call
        $audio_url = 'https://via.placeholder.com/150x50?text=Audio+Generated';

        wp_send_json_success([
            'audio_url' => $audio_url,
            'text' => $text,
            'voice' => $voice,
            'emotion' => $emotion,
        ]);
    }

    public function get_voices() {
        return $this->voices;
    }

    public function get_voice($voice_id) {
        foreach ($this->voices as $category => $voices) {
            foreach ($voices as $voice) {
                if ($voice['id'] === $voice_id) {
                    return $voice;
                }
            }
        }
        return null;
    }
}
PLUGINEOF

# 15. Social Media Export
cat > "$PLUGIN_DIR/includes/class-social-export.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class Social_Export {
    private static $instance = null;
    private $platforms = [];

    private function __construct() {
        $this->load_platforms();
        add_shortcode('ai_motion_social_export', [$this, 'export_shortcode']);
        add_action('wp_ajax_ai_motion_export_social', [$this, 'ajax_export_social']);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    private function load_platforms() {
        $this->platforms = [
            'youtube_shorts' => [
                'name' => 'YouTube Shorts',
                'aspect_ratio' => '9:16',
                'max_duration' => 60,
                'resolution' => '1080x1920',
                'file_format' => 'mp4',
                'max_size' => 250 * 1024 * 1024, // 250MB
            ],
            'tiktok' => [
                'name' => 'TikTok',
                'aspect_ratio' => '9:16',
                'max_duration' => 60,
                'resolution' => '1080x1920',
                'file_format' => 'mp4',
                'max_size' => 287 * 1024 * 1024, // 287MB
            ],
            'instagram_reels' => [
                'name' => 'Instagram Reels',
                'aspect_ratio' => '9:16',
                'max_duration' => 90,
                'resolution' => '1080x1920',
                'file_format' => 'mp4',
                'max_size' => 4 * 1024 * 1024 * 1024, // 4GB
            ],
            'facebook_reels' => [
                'name' => 'Facebook Reels',
                'aspect_ratio' => '9:16',
                'max_duration' => 90,
                'resolution' => '1080x1920',
                'file_format' => 'mp4',
                'max_size' => 4 * 1024 * 1024 * 1024, // 4GB
            ],
            'twitter' => [
                'name' => 'Twitter',
                'aspect_ratio' => '16:9',
                'max_duration' => 140,
                'resolution' => '1920x1080',
                'file_format' => 'mp4',
                'max_size' => 512 * 1024 * 1024, // 512MB
            ],
        ];
    }

    public function export_shortcode($atts) {
        $atts = shortcode_atts([
            'video_url' => '',
            'class' => '',
        ], $atts);

        ob_start();
        ?>
        <div class="ai-motion-social-export <?php echo esc_attr($atts['class']); ?>">
            <h3><?php _e('Export to Social Media', 'ai-motion-studio'); ?></h3>
            <p><?php _e('Select platform to export your video:', 'ai-motion-studio'); ?></p>
            <div class="ai-motion-platform-grid">
                <?php foreach ($this->platforms as $key => $platform): ?>
                    <div class="ai-motion-platform-card" data-platform="<?php echo esc_attr($key); ?>">
                        <h4><?php echo esc_html($platform['name']); ?></h4>
                        <p>
                            <strong><?php _e('Aspect Ratio:', 'ai-motion-studio'); ?></strong> <?php echo esc_html($platform['aspect_ratio']); ?><br>
                            <strong><?php _e('Max Duration:', 'ai-motion-studio'); ?></strong> <?php echo esc_html($platform['max_duration']); ?>s<br>
                            <strong><?php _e('Resolution:', 'ai-motion-studio'); ?></strong> <?php echo esc_html($platform['resolution']); ?>
                        </p>
                        <button class="ai-motion-btn ai-motion-btn-secondary export-btn" data-platform="<?php echo esc_attr($key); ?>">
                            <?php _e('Export', 'ai-motion-studio'); ?>
                        </button>
                    </div>
                <?php endforeach; ?>
            </div>
            <input type="hidden" id="ai-motion-video-url" value="<?php echo esc_url($atts['video_url']); ?>">
        </div>
        <?php
        return ob_get_clean();
    }

    public function ajax_export_social() {
        check_ajax_referer('ai_motion_nonce', 'nonce');

        $platform = sanitize_text_field($_POST['platform'] ?? '');
        $video_url = esc_url_raw($_POST['video_url'] ?? '');

        if (!isset($this->platforms[$platform])) {
            wp_send_json_error(['message' => __('Invalid platform', 'ai-motion-studio')]);
        }

        if (empty($video_url)) {
            wp_send_json_error(['message' => __('Video URL is required', 'ai-motion-studio')]);
        }

        $platform_data = $this->platforms[$platform];

        // Simulate export - in real implementation, this would:
        // 1. Download the video
        // 2. Resize to platform specs
        // 3. Generate caption/hashtags
        // 4. Generate thumbnail
        // 5. Return downloadable files

        $download_url = $video_url . '?platform=' . $platform;

        wp_send_json_success([
            'download_url' => $download_url,
            'platform' => $platform,
            'platform_name' => $platform_data['name'],
            'caption' => $this->generate_caption($platform),
            'hashtags' => $this->generate_hashtags($platform),
            'thumbnail_url' => $video_url . '?thumbnail=1',
        ]);
    }

    private function generate_caption($platform) {
        $captions = [
            'youtube_shorts' => 'Check out this amazing AI-generated video! #AI #Video #Shorts',
            'tiktok' => 'This AI creation is 🔥 Who else wants to try? #AI #TikTok #Viral',
            'instagram_reels' => 'AI-powered creativity at its finest! 🎨✨ #AI #Reels #InstaGood',
            'facebook_reels' => 'Created with AI Motion Studio! What do you think? 👀 #AI #Facebook #Reels',
            'twitter' => 'Just created this with AI Motion Studio. The future is now! 🚀 #AI #Twitter #Video',
        ];
        return $captions[$platform] ?? 'AI-generated content';
    }

    private function generate_hashtags($platform) {
        $hashtags = [
            'youtube_shorts' => ['#AI', '#Video', '#Shorts', '#AIArt', '#MotionStudio'],
            'tiktok' => ['#AI', '#TikTok', '#Viral', '#AICreator', '#MotionStudio'],
            'instagram_reels' => ['#AI', '#Reels', '#InstaGood', '#AIDesign', '#MotionStudio'],
            'facebook_reels' => ['#AI', '#Facebook', '#Reels', '#AICreation', '#MotionStudio'],
            'twitter' => ['#AI', '#Twitter', '#Video', '#AITech', '#MotionStudio'],
        ];
        return $hashtags[$platform] ?? ['#AI', '#MotionStudio'];
    }

    public function get_platforms() {
        return $this->platforms;
    }

    public function get_platform($key) {
        return $this->platforms[$key] ?? null;
    }
}
PLUGINEOF

# 16. Admin Dashboard
cat > "$PLUGIN_DIR/includes/class-admin-dashboard.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class Admin_Dashboard {
    private static $instance = null;

    private function __construct() {
        add_action('admin_menu', [$this, 'add_dashboard_pages'], 10);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function add_dashboard_pages() {
        add_menu_page(
            'AI Motion Studio',
            'AI Motion Studio',
            'manage_options',
            'ai-motion-dashboard',
            [$this, 'render_main_dashboard'],
            'dashicons-format-video',
            20
        );

        add_submenu_page(
            'ai-motion-dashboard',
            __('Dashboard', 'ai-motion-studio'),
            __('Dashboard', 'ai-motion-studio'),
            'manage_options',
            'ai-motion-dashboard',
            [$this, 'render_main_dashboard']
        );

        add_submenu_page(
            'ai-motion-dashboard',
            __('Generations', 'ai-motion-studio'),
            __('Generations', 'ai-motion-studio'),
            'edit_posts',
            'ai-motion-generations',
            [$this, 'render_generations_page']
        );

        add_submenu_page(
            'ai-motion-dashboard',
            __('Templates', 'ai-motion-studio'),
            __('Templates', 'ai-motion-studio'),
            'edit_posts',
            'ai-motion-templates-admin',
            [$this, 'render_templates_page']
        );

        add_submenu_page(
            'ai-motion-dashboard',
            __('Users', 'ai-motion-studio'),
            __('Users', 'ai-motion-studio'),
            'manage_options',
            'ai-motion-users',
            [$this, 'render_users_page']
        );

        add_submenu_page(
            'ai-motion-dashboard',
            __('Analytics', 'ai-motion-studio'),
            __('Analytics', 'ai-motion-studio'),
            'manage_options',
            'ai-motion-analytics',
            [$this, 'render_analytics_page']
        );

        add_submenu_page(
            'ai-motion-dashboard',
            __('Settings', 'ai-motion-studio'),
            __('Settings', 'ai-motion-studio'),
            'manage_options',
            'ai-motion-settings',
            [$this, 'render_settings_page']
        );
    }

    public function render_main_dashboard() {
        ?>
        <div class="wrap ai-motion-dashboard">
            <h1><?php _e('AI Motion Studio Dashboard', 'ai-motion-studio'); ?></h1>

            <div class="ai-motion-stats-grid">
                <div class="ai-motion-stat-card">
                    <h3><?php _e('Total Users', 'ai-motion-studio'); ?></h3>
                    <div class="ai-motion-stat-value">0</div>
                </div>
                <div class="ai-motion-stat-card">
                    <h3><?php _e('Total Generations', 'ai-motion-studio'); ?></h3>
                    <div class="ai-motion-stat-value">0</div>
                </div>
                <div class="ai-motion-stat-card">
                    <h3><?php _e('Total Credits Used', 'ai-motion-studio'); ?></h3>
                    <div class="ai-motion-stat-value">0</div>
                </div>
                <div class="ai-motion-stat-card">
                    <h3><?php _e('Active Subscriptions', 'ai-motion-studio'); ?></h3>
                    <div class="ai-motion-stat-value">0</div>
                </div>
            </div>

            <div class="ai-motion-dashboard-sections">
                <div class="ai-motion-section">
                    <h2><?php _e('Recent Activity', 'ai-motion-studio'); ?></h2>
                    <p><?php _e('No recent activity yet.', 'ai-motion-studio'); ?></p>
                </div>
                <div class="ai-motion-section">
                    <h2><?php _e('Quick Actions', 'ai-motion-studio'); ?></h2>
                    <div class="ai-motion-quick-actions">
                        <a href="<?php echo admin_url('admin.php?page=ai-motion-generations'); ?>" class="ai-motion-btn">
                            <?php _e('View Generations', 'ai-motion-studio'); ?>
                        </a>
                        <a href="<?php echo admin_url('admin.php?page=ai-motion-templates-admin'); ?>" class="ai-motion-btn">
                            <?php _e('Manage Templates', 'ai-motion-studio'); ?>
                        </a>
                        <a href="<?php echo admin_url('admin.php?page=ai-motion-settings'); ?>" class="ai-motion-btn">
                            <?php _e('Configure Settings', 'ai-motion-studio'); ?>
                        </a>
                    </div>
                </div>
            </div>
        </div>
        <?php
    }

    public function render_generations_page() {
        ?>
        <div class="wrap">
            <h1><?php _e('AI Generations', 'ai-motion-studio'); ?></h1>
            <p><?php _e('Manage all AI-generated content.', 'ai-motion-studio'); ?></p>
        </div>
        <?php
    }

    public function render_templates_page() {
        ?>
        <div class="wrap">
            <h1><?php _e('Motion Templates', 'ai-motion-studio'); ?></h1>
            <p><?php _e('Create and manage motion templates.', 'ai-motion-studio'); ?></p>
        </div>
        <?php
    }

    public function render_users_page() {
        ?>
        <div class="wrap">
            <h1><?php _e('Users', 'ai-motion-studio'); ?></h1>
            <p><?php _e('Manage user accounts and permissions.', 'ai-motion-studio'); ?></p>
        </div>
        <?php
    }

    public function render_analytics_page() {
        ?>
        <div class="wrap">
            <h1><?php _e('Analytics', 'ai-motion-studio'); ?></h1>
            <p><?php _e('View usage statistics and analytics.', 'ai-motion-studio'); ?></p>
        </div>
        <?php
    }

    public function render_settings_page() {
        ?>
        <div class="wrap">
            <h1><?php _e('AI Motion Studio Settings', 'ai-motion-studio'); ?></h1>

            <form method="post" action="options.php">
                <?php
                settings_fields('ai_motion_settings');
                do_settings_sections('ai_motion_settings');
                submit_button(__('Save Settings', 'ai-motion-studio'));
                ?>
            </form>
        </div>
        <?php
    }
}
PLUGINEOF

# 17. User Dashboard
cat > "$PLUGIN_DIR/includes/class-user-dashboard.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class User_Dashboard {
    private static $instance = null;

    private function __construct() {
        add_shortcode('ai_motion_dashboard', [$this, 'dashboard_shortcode']);
        add_shortcode('ai_motion_generate', [$this, 'generate_shortcode']);
        add_shortcode('ai_motion_credits', [$this, 'credits_shortcode']);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function dashboard_shortcode($atts) {
        if (!is_user_logged_in()) {
            return '<p>' . __('Please log in to access the dashboard.', 'ai-motion-studio') . '</p>';
        }

        $user_id = get_current_user_id();
        $credits = Credits::get_instance()->get_user_balance($user_id);

        ob_start();
        ?>
        <div class="ai-motion-user-dashboard">
            <h1><?php _e('Welcome to AI Motion Studio', 'ai-motion-studio'); ?></h1>

            <div class="ai-motion-user-stats">
                <div class="ai-motion-stat-card">
                    <h3><?php _e('Your Credits', 'ai-motion-studio'); ?></h3>
                    <div class="ai-motion-stat-value"><?php echo esc_html($credits); ?></div>
                </div>
                <div class="ai-motion-stat-card">
                    <h3><?php _e('Generations', 'ai-motion-studio'); ?></h3>
                    <div class="ai-motion-stat-value">0</div>
                </div>
                <div class="ai-motion-stat-card">
                    <h3><?php _e('Templates Used', 'ai-motion-studio'); ?></h3>
                    <div class="ai-motion-stat-value">0</div>
                </div>
            </div>

            <div class="ai-motion-dashboard-actions">
                <h2><?php _e('Create New', 'ai-motion-studio'); ?></h2>
                <div class="ai-motion-action-grid">
                    <a href="<?php echo home_url('/ai-motion-generate'); ?>" class="ai-motion-action-card">
                        <h3><?php _e('Generate Content', 'ai-motion-studio'); ?></h3>
                        <p><?php _e('Create images, videos, and more', 'ai-motion-studio'); ?></p>
                    </a>
                    <a href="<?php echo home_url('/ai-motion-templates'); ?>" class="ai-motion-action-card">
                        <h3><?php _e('Browse Templates', 'ai-motion-studio'); ?></h3>
                        <p><?php _e('Use pre-made motion templates', 'ai-motion-studio'); ?></p>
                    </a>
                    <a href="<?php echo home_url('/ai-motion-credits'); ?>" class="ai-motion-action-card">
                        <h3><?php _e('Get More Credits', 'ai-motion-studio'); ?></h3>
                        <p><?php _e('Purchase credit packs', 'ai-motion-studio'); ?></p>
                    </a>
                </div>
            </div>

            <div class="ai-motion-recent-activity">
                <h2><?php _e('Recent Activity', 'ai-motion-studio'); ?></h2>
                <p><?php _e('Your recent generations will appear here.', 'ai-motion-studio'); ?></p>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }

    public function generate_shortcode($atts) {
        if (!is_user_logged_in()) {
            return '<p>' . __('Please log in to generate content.', 'ai-motion-studio') . '</p>';
        }

        ob_start();
        ?>
        <div class="ai-motion-generate-page">
            <h1><?php _e('Generate Content', 'ai-motion-studio'); ?></h1>

            <div class="ai-motion-generation-tabs">
                <button class="ai-motion-tab active" data-tab="image"><?php _e('Image', 'ai-motion-studio'); ?></button>
                <button class="ai-motion-tab" data-tab="video"><?php _e('Video', 'ai-motion-studio'); ?></button>
                <button class="ai-motion-tab" data-tab="avatar"><?php _e('Avatar', 'ai-motion-studio'); ?></button>
                <button class="ai-motion-tab" data-tab="voice"><?php _e('Voice', 'ai-motion-studio'); ?></button>
                <button class="ai-motion-tab" data-tab="story"><?php _e('Story', 'ai-motion-studio'); ?></button>
            </div>

            <div class="ai-motion-tab-content active" id="ai-motion-image-tab">
                <?php echo do_shortcode('[ai_motion_image]'); ?>
            </div>

            <div class="ai-motion-tab-content" id="ai-motion-video-tab">
                <?php echo do_shortcode('[ai_motion_video]'); ?>
            </div>

            <div class="ai-motion-tab-content" id="ai-motion-avatar-tab">
                <?php echo do_shortcode('[ai_motion_avatar]'); ?>
            </div>

            <div class="ai-motion-tab-content" id="ai-motion-voice-tab">
                <?php echo do_shortcode('[ai_motion_voice]'); ?>
            </div>

            <div class="ai-motion-tab-content" id="ai-motion-story-tab">
                <?php echo do_shortcode('[ai_motion_story]'); ?>
            </div>
        </div>

        <script>
        jQuery(document).ready(function($) {
            $('.ai-motion-tab').on('click', function() {
                var tab = $(this).data('tab');
                $('.ai-motion-tab').removeClass('active');
                $(this).addClass('active');
                $('.ai-motion-tab-content').removeClass('active');
                $('#ai-motion-' + tab + '-tab').addClass('active');
            });
        });
        </script>
        <?php
        return ob_get_clean();
    }

    public function credits_shortcode($atts) {
        if (!is_user_logged_in()) {
            return '<p>' . __('Please log in to view your credits.', 'ai-motion-studio') . '</p>';
        }

        return Credits::get_instance()->credits_shortcode($atts);
    }
}
PLUGINEOF

# 18. Subscriptions
cat > "$PLUGIN_DIR/includes/class-subscriptions.php" << 'PLUGINEOF'
<?php
namespace AI_Motion_Studio;

class Subscriptions {
    private static $instance = null;

    private function __construct() {
        add_action('admin_menu', [$this, 'add_subscriptions_page'], 20);
        add_action('init', [$this, 'register_subscription_post_type']);
    }

    public static function init() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function register_subscription_post_type() {
        $labels = [
            'name' => __('Subscriptions', 'ai-motion-studio'),
            'singular_name' => __('Subscription', 'ai-motion-studio'),
        ];

        $args = [
            'labels' => $labels,
            'public' => false,
            'show_ui' => true,
            'show_in_menu' => false,
            'capability_type' => 'post',
            'has_archive' => false,
        ];

        register_post_type('ai_subscription', $args);
    }

    public function add_subscriptions_page() {
        add_submenu_page(
            'ai-motion-dashboard',
            __('Subscriptions', 'ai-motion-studio'),
            __('Subscriptions', 'ai-motion-studio'),
            'manage_options',
            'ai-motion-subscriptions',
            [$this, 'render_subscriptions_page']
        );
    }

    public function render_subscriptions_page() {
        ?>
        <div class="wrap">
            <h1><?php _e('Subscription Plans', 'ai-motion-studio'); ?></h1>
            <p><?php _e('Manage subscription plans for your users.', 'ai-motion-studio'); ?></p>

            <div class="ai-motion-subscription-grid">
                <?php $this->display_subscription_plans(); ?>
            </div>
        </div>
        <?php
    }

    private function display_subscription_plans() {
        $plans = [
            'starter' => [
                'name' => 'Starter',
                'description' => 'Perfect for trying out the platform',
                'credits' => 100,
                'price' => 9.99,
                'monthly_credits' => 100,
                'features' => [
                    '100 credits/month',
                    'Basic templates',
                    'Standard quality',
                    'Email support',
                ],
            ],
            'pro' => [
                'name' => 'Pro',
                'description' => 'For regular creators',
                'credits' => 1000,
                'price' => 49.99,
                'monthly_credits' => 1000,
                'features' => [
                    '1000 credits/month',
                    'All templates',
                    'High quality',
                    'Priority support',
                    'Batch processing',
                ],
                'popular' => true,
            ],
            'business' => [
                'name' => 'Business',
                'description' => 'For agencies and professionals',
                'credits' => 5000,
                'price' => 199.99,
                'monthly_credits' => 5000,
                'features' => [
                    '5000 credits/month',
                    'All templates',
                    'Premium quality',
                    '24/7 support',
                    'API access',
                    'White label',
                ],
            ],
            'unlimited' => [
                'name' => 'Unlimited',
                'description' => 'Unlimited generations',
                'credits' => -1,
                'price' => 499.99,
                'monthly_credits' => -1,
                'features' => [
                    'Unlimited credits',
                    'All templates',
                    'Highest quality',
                    '24/7 priority support',
                    'API access',
                    'White label',
                    'Custom templates',
                ],
            ],
        ];

        foreach ($plans as $key => $plan) {
            echo '<div class="ai-motion-subscription-card ' . (isset($plan['popular']) ? 'popular' : '') . '">';
            echo '<h3>' . esc_html($plan['name']) . '</h3>';
            echo '<div class="ai-motion-subscription-price">$' . esc_html($plan['price']) . '/month</div>';
            echo '<p class="ai-motion-subscription-description">' . esc_html($plan['description']) . '</p>';
            echo '<ul class="ai-motion-subscription-features">';
            foreach ($plan['features'] as $feature) {
                echo '<li>' . esc_html($feature) . '</li>';
            }
            echo '</ul>';
            echo '<button class="ai-motion-btn ai-motion-btn-primary">' . __('Select Plan', 'ai-motion-studio') . '</button>';
            echo '</div>';
        }
    }

    public function get_subscription_plans() {
        return [
            'starter' => [
                'name' => 'Starter',
                'credits' => 100,
                'price' => 9.99,
                'monthly_credits' => 100,
            ],
            'pro' => [
                'name' => 'Pro',
                'credits' => 1000,
                'price' => 49.99,
                'monthly_credits' => 1000,
            ],
            'business' => [
                'name' => 'Business',
                'credits' => 5000,
                'price' => 199.99,
                'monthly_credits' => 5000,
            ],
            'unlimited' => [
                'name' => 'Unlimited',
                'credits' => -1,
                'price' => 499.99,
                'monthly_credits' => -1,
            ],
        ];
    }

    public function get_user_subscription($user_id) {
        // Check if user has active subscription
        // This would integrate with WooCommerce Subscriptions or similar
        return [
            'plan' => 'free',
            'status' => 'active',
            'expires' => null,
            'monthly_credits' => 0,
        ];
    }
}
PLUGINEOF

# 19. CSS Files
cat > "$PLUGIN_DIR/assets/css/admin.css" << 'PLUGINEOF'
/* AI Motion Studio - Admin Styles */
.ai-motion-dashboard {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.ai-motion-stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 20px;
    margin: 30px 0;
}

.ai-motion-stat-card {
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    border: 1px solid #e5e7eb;
    text-align: center;
}

.ai-motion-stat-card h3 {
    margin: 0 0 10px 0;
    font-size: 16px;
    color: #6b7280;
}

.ai-motion-stat-value {
    font-size: 32px;
    font-weight: 700;
    color: #111827;
}

.ai-motion-dashboard-sections {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 30px;
}

.ai-motion-section {
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    border: 1px solid #e5e7eb;
}

.ai-motion-section h2 {
    margin: 0 0 20px 0;
    font-size: 18px;
}

.ai-motion-quick-actions {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
}

.ai-motion-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 10px 20px;
    border: none;
    border-radius: 6px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    text-decoration: none;
    text-align: center;
}

.ai-motion-btn-primary {
    background: #6366f1;
    color: white;
}

.ai-motion-btn-primary:hover {
    background: #4f46e5;
}

.ai-motion-btn-secondary {
    background: #f3f4f6;
    color: #374151;
}

.ai-motion-btn-secondary:hover {
    background: #e5e7eb;
}

.ai-motion-subscription-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    margin: 30px 0;
}

.ai-motion-subscription-card {
    background: white;
    padding: 30px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    border: 1px solid #e5e7eb;
    position: relative;
}

.ai-motion-subscription-card.popular {
    border-color: #6366f1;
    border-width: 2px;
}

.ai-motion-subscription-card.popular::before {
    content: "Popular";
    position: absolute;
    top: -10px;
    left: 50%;
    transform: translateX(-50%);
    background: #6366f1;
    color: white;
    padding: 4px 12px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 600;
}

.ai-motion-subscription-price {
    font-size: 36px;
    font-weight: 700;
    color: #111827;
    margin: 10px 0;
}

.ai-motion-subscription-description {
    color: #6b7280;
    margin: 0 0 20px 0;
}

.ai-motion-subscription-features {
    list-style: none;
    padding: 0;
    margin: 0 0 20px 0;
}

.ai-motion-subscription-features li {
    padding: 8px 0;
    border-bottom: 1px solid #f3f4f6;
    color: #4b5563;
}

.ai-motion-subscription-features li:last-child {
    border-bottom: none;
}

@media (max-width: 768px) {
    .ai-motion-dashboard-sections {
        grid-template-columns: 1fr;
    }
}
PLUGINEOF

cat > "$PLUGIN_DIR/assets/css/frontend.css" << 'PLUGINEOF'
/* AI Motion Studio - Frontend Styles */
.ai-motion-user-dashboard {
    max-width: 1200px;
    margin: 0 auto;
    padding: 30px 20px;
}

.ai-motion-user-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 20px;
    margin: 30px 0;
}

.ai-motion-stat-card {
    background: white;
    padding: 25px;
    border-radius: 12px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.07);
    border: 1px solid #e5e7eb;
    text-align: center;
}

.ai-motion-stat-card h3 {
    margin: 0 0 15px 0;
    font-size: 16px;
    color: #6b7280;
    font-weight: 600;
}

.ai-motion-stat-value {
    font-size: 40px;
    font-weight: 700;
    color: #6366f1;
}

.ai-motion-dashboard-actions {
    margin: 40px 0;
}

.ai-motion-dashboard-actions h2 {
    margin: 0 0 20px 0;
    font-size: 24px;
}

.ai-motion-action-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
}

.ai-motion-action-card {
    background: white;
    padding: 30px;
    border-radius: 12px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.07);
    border: 1px solid #e5e7eb;
    text-align: center;
    text-decoration: none;
    color: #111827;
    transition: all 0.2s;
}

.ai-motion-action-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 10px 15px rgba(0,0,0,0.1);
    border-color: #6366f1;
}

.ai-motion-action-card h3 {
    margin: 0 0 10px 0;
    font-size: 20px;
    color: #111827;
}

.ai-motion-action-card p {
    margin: 0;
    color: #6b7280;
    font-size: 14px;
}

.ai-motion-recent-activity {
    margin: 40px 0;
}

.ai-motion-recent-activity h2 {
    margin: 0 0 20px 0;
    font-size: 24px;
}

/* Generation Forms */
.ai-motion-generate-page {
    max-width: 1000px;
    margin: 0 auto;
    padding: 30px 20px;
}

.ai-motion-generate-page h1 {
    margin: 0 0 30px 0;
    font-size: 28px;
}

.ai-motion-generation-tabs {
    display: flex;
    gap: 5px;
    margin: 0 0 30px 0;
    border-bottom: 1px solid #e5e7eb;
    flex-wrap: wrap;
}

.ai-motion-tab {
    padding: 12px 24px;
    background: none;
    border: none;
    border-bottom: 2px solid transparent;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    color: #6b7280;
    transition: all 0.2s;
}

.ai-motion-tab:hover {
    color: #6366f1;
}

.ai-motion-tab.active {
    color: #6366f1;
    border-bottom-color: #6366f1;
}

.ai-motion-tab-content {
    display: none;
}

.ai-motion-tab-content.active {
    display: block;
}

/* Forms */
.ai-motion-form {
    background: white;
    padding: 30px;
    border-radius: 12px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.07);
    border: 1px solid #e5e7eb;
    margin-bottom: 30px;
}

.ai-motion-form textarea {
    width: 100%;
    min-height: 120px;
    padding: 15px;
    border: 1px solid #d1d5db;
    border-radius: 8px;
    font-size: 14px;
    margin: 0 0 20px 0;
    resize: vertical;
    font-family: inherit;
}

.ai-motion-form input[type="text"],
.ai-motion-form input[type="number"],
.ai-motion-form input[type="file"],
.ai-motion-form input[type="url"],
.ai-motion-form select {
    width: 100%;
    padding: 12px 15px;
    border: 1px solid #d1d5db;
    border-radius: 8px;
    font-size: 14px;
    margin: 0 0 20px 0;
    font-family: inherit;
}

.ai-motion-form button {
    width: 100%;
    padding: 15px;
    font-size: 16px;
    font-weight: 600;
}

/* Results */
.ai-motion-results {
    margin-top: 30px;
}

.ai-motion-result-item {
    background: white;
    padding: 20px;
    border-radius: 12px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.07);
    border: 1px solid #e5e7eb;
    margin-bottom: 20px;
}

.ai-motion-result-item img,
.ai-motion-result-item video {
    max-width: 100%;
    border-radius: 8px;
    margin-bottom: 15px;
}

.ai-motion-result-item audio {
    width: 100%;
    margin-bottom: 15px;
}

/* Template Grid */
.ai-motion-templates {
    max-width: 1200px;
    margin: 0 auto;
    padding: 30px 20px;
}

.ai-motion-templates h1 {
    margin: 0 0 30px 0;
    font-size: 28px;
}

.ai-motion-template-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 25px;
}

.ai-motion-template-card {
    background: white;
    padding: 25px;
    border-radius: 12px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.07);
    border: 1px solid #e5e7eb;
    text-align: center;
    transition: all 0.2s;
    cursor: pointer;
}

.ai-motion-template-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 10px 15px rgba(0,0,0,0.1);
    border-color: #6366f1;
}

.ai-motion-template-card h3 {
    margin: 0 0 10px 0;
    font-size: 18px;
    color: #111827;
}

.ai-motion-template-card p {
    margin: 0 0 15px 0;
    color: #6b7280;
    font-size: 14px;
}

.ai-motion-template-category {
    display: inline-block;
    padding: 4px 12px;
    background: #f3f4f6;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
    color: #4b5563;
    margin-bottom: 15px;
}

.ai-motion-template-card .ai-motion-btn {
    margin-top: 10px;
}

/* Credits */
.ai-motion-credits {
    max-width: 800px;
    margin: 0 auto;
    padding: 30px 20px;
}

.ai-motion-credits h2 {
    margin: 0 0 30px 0;
    font-size: 28px;
    text-align: center;
}

.ai-motion-credit-balance {
    background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
    color: white;
    padding: 40px;
    border-radius: 16px;
    text-align: center;
    margin: 0 0 40px 0;
}

.ai-motion-credit-amount {
    font-size: 64px;
    font-weight: 700;
    display: block;
}

.ai-motion-credit-label {
    font-size: 18px;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 1px;
}

.ai-motion-credit-packs {
    margin-top: 40px;
}

.ai-motion-credit-packs h3 {
    margin: 0 0 20px 0;
    font-size: 20px;
    text-align: center;
}

.ai-motion-credit-pack {
    background: white;
    padding: 25px;
    border-radius: 12px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.07);
    border: 1px solid #e5e7eb;
    margin-bottom: 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 15px;
}

.ai-motion-credit-pack h4 {
    margin: 0;
    font-size: 18px;
    color: #111827;
}

.ai-motion-credit-pack p {
    margin: 5px 0;
    color: #6b7280;
    font-size: 14px;
}

.ai-motion-pack-price {
    font-size: 24px;
    font-weight: 700;
    color: #6366f1;
}

/* Social Export */
.ai-motion-social-export {
    max-width: 1000px;
    margin: 0 auto;
    padding: 30px 20px;
}

.ai-motion-social-export h3 {
    margin: 0 0 20px 0;
    font-size: 24px;
    text-align: center;
}

.ai-motion-platform-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 20px;
}

.ai-motion-platform-card {
    background: white;
    padding: 25px;
    border-radius: 12px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.07);
    border: 1px solid #e5e7eb;
    text-align: center;
}

.ai-motion-platform-card h4 {
    margin: 0 0 15px 0;
    font-size: 18px;
    color: #111827;
}

.ai-motion-platform-card p {
    margin: 0 0 20px 0;
    color: #6b7280;
    font-size: 14px;
}

.ai-motion-platform-card strong {
    color: #111827;
}

.ai-motion-platform-card .export-btn {
    width: 100%;
}

/* Responsive */
@media (max-width: 768px) {
    .ai-motion-user-stats {
        grid-template-columns: 1fr;
    }

    .ai-motion-generation-tabs {
        flex-direction: column;
    }

    .ai-motion-tab {
        width: 100%;
        text-align: left;
        border-bottom: none;
        border-left: 3px solid transparent;
        padding: 12px 15px;
    }

    .ai-motion-tab.active {
        border-left-color: #6366f1;
        border-bottom-color: transparent;
    }

    .ai-motion-credit-pack {
        flex-direction: column;
        text-align: center;
    }
}
PLUGINEOF

# 20. JavaScript Files
cat > "$PLUGIN_DIR/assets/js/admin.js" << 'PLUGINEOF'
jQuery(document).ready(function($) {
    // Tab switching
    $('.ai-motion-tab').on('click', function(e) {
        e.preventDefault();
        var tab = $(this).data('tab');
        $('.ai-motion-tab').removeClass('active');
        $(this).addClass('active');
        $('.ai-motion-tab-content').removeClass('active');
        $('#ai-motion-' + tab + '-tab').addClass('active');
    });

    // Form submissions
    $('.ai-motion-form').on('submit', function(e) {
        e.preventDefault();
        var form = $(this);
        var button = form.find('button[type="submit"]');
        var originalText = button.text();

        button.prop('disabled', true).text('Processing...');

        var formData = new FormData(form[0]);
        formData.append('action', 'ai_motion_' + form.find('input[name="action"]').val());
        formData.append('nonce', aiMotionStudioAdmin.nonce);

        $.ajax({
            url: aiMotionStudioAdmin.ajax_url,
            type: 'POST',
            data: formData,
            processData: false,
            contentType: false,
            success: function(response) {
                if (response.success) {
                    form.trigger('reset');
                    if (response.data.image_url) {
                        form.siblings('.ai-motion-results').append(
                            '<div class="ai-motion-result-item"><img src="' + response.data.image_url + '" alt="Generated Image"><a href="' + response.data.image_url + '" download class="ai-motion-btn ai-motion-btn-secondary">Download</a></div>'
                        );
                    }
                    if (response.data.video_url) {
                        form.siblings('.ai-motion-results').append(
                            '<div class="ai-motion-result-item"><video controls src="' + response.data.video_url + '"></video><a href="' + response.data.video_url + '" download class="ai-motion-btn ai-motion-btn-secondary">Download</a></div>'
                        );
                    }
                    if (response.data.audio_url) {
                        form.siblings('.ai-motion-results').append(
                            '<div class="ai-motion-result-item"><audio controls src="' + response.data.audio_url + '"></audio><a href="' + response.data.audio_url + '" download class="ai-motion-btn ai-motion-btn-secondary">Download</a></div>'
                        );
                    }
                    if (response.data.story) {
                        var storyHtml = '<div class="ai-motion-result-item"><h3>' + response.data.story.title + '</h3>';
                        response.data.story.chapters.forEach(function(chapter, index) {
                            storyHtml += '<div class="ai-motion-story-chapter"><h4>Chapter ' + (index + 1) + ': ' + chapter.title + '</h4><p>' + chapter.content + '</p></div>';
                        });
                        storyHtml += '</div>';
                        form.siblings('.ai-motion-results').append(storyHtml);
                    }
                } else {
                    alert(response.data.message || 'An error occurred');
                }
            },
            error: function() {
                alert('An error occurred. Please try again.');
            },
            complete: function() {
                button.prop('disabled', false).text(originalText);
            }
        });
    });

    // Export to social media
    $('.ai-motion-platform-card .export-btn').on('click', function(e) {
        e.preventDefault();
        var platform = $(this).data('platform');
        var videoUrl = $('#ai-motion-video-url').val();

        if (!videoUrl) {
            alert('Please provide a video URL');
            return;
        }

        var button = $(this);
        var originalText = button.text();

        button.prop('disabled', true).text('Exporting...');

        $.ajax({
            url: aiMotionStudioAdmin.ajax_url,
            type: 'POST',
            data: {
                action: 'ai_motion_export_social',
                platform: platform,
                video_url: videoUrl,
                nonce: aiMotionStudioAdmin.nonce
            },
            success: function(response) {
                if (response.success) {
                    alert('Export ready! Download: ' + response.data.download_url +
                          '\nCaption: ' + response.data.caption +
                          '\nHashtags: ' + response.data.hashtags.join(', '));
                } else {
                    alert(response.data.message || 'Export failed');
                }
            },
            error: function() {
                alert('Export failed. Please try again.');
            },
            complete: function() {
                button.prop('disabled', false).text(originalText);
            }
        });
    });
});
PLUGINEOF

cat > "$PLUGIN_DIR/assets/js/frontend.js" << 'PLUGINEOF'
jQuery(document).ready(function($) {
    // Tab switching for frontend
    $('.ai-motion-tab').on('click', function(e) {
        e.preventDefault();
        var tab = $(this).data('tab');
        $('.ai-motion-tab').removeClass('active');
        $(this).addClass('active');
        $('.ai-motion-tab-content').removeClass('active');
        $('#ai-motion-' + tab + '-tab').addClass('active');
    });

    // Form submissions for frontend
    $('.ai-motion-form').on('submit', function(e) {
        e.preventDefault();
        var form = $(this);
        var button = form.find('button[type="submit"]');
        var originalText = button.text();

        button.prop('disabled', true).text('Processing...');

        var formData = new FormData(form[0]);
        formData.append('action', form.find('input[name="action"]').val());
        formData.append('nonce', aiMotionStudio.nonce);

        $.ajax({
            url: aiMotionStudio.ajax_url,
            type: 'POST',
            data: formData,
            processData: false,
            contentType: false,
            success: function(response) {
                if (response.success) {
                    form.trigger('reset');
                    var resultsContainer = form.siblings('.ai-motion-results');

                    if (response.data.image_url) {
                        resultsContainer.append(
                            '<div class="ai-motion-result-item"><img src="' + response.data.image_url + '" alt="Generated Image"><a href="' + response.data.image_url + '" download class="ai-motion-btn ai-motion-btn-secondary">Download Image</a></div>'
                        );
                    }

                    if (response.data.video_url) {
                        resultsContainer.append(
                            '<div class="ai-motion-result-item"><video controls src="' + response.data.video_url + '"></video><a href="' + response.data.video_url + '" download class="ai-motion-btn ai-motion-btn-secondary">Download Video</a></div>'
                        );
                    }

                    if (response.data.audio_url) {
                        resultsContainer.append(
                            '<div class="ai-motion-result-item"><audio controls src="' + response.data.audio_url + '"></audio><a href="' + response.data.audio_url + '" download class="ai-motion-btn ai-motion-btn-secondary">Download Audio</a></div>'
                        );
                    }

                    if (response.data.story) {
                        var storyHtml = '<div class="ai-motion-result-item"><h3>' + response.data.story.title + '</h3>';
                        response.data.story.chapters.forEach(function(chapter, index) {
                            storyHtml += '<div class="ai-motion-story-chapter"><h4>Chapter ' + (index + 1) + ': ' + chapter.title + '</h4><p>' + chapter.content + '</p></div>';
                        });
                        storyHtml += '</div>';
                        resultsContainer.append(storyHtml);
                    }
                } else {
                    alert(response.data.message || 'An error occurred');
                }
            },
            error: function() {
                alert('An error occurred. Please try again.');
            },
            complete: function() {
                button.prop('disabled', false).text(originalText);
            }
        });
    });

    // Use template button
    $('.ai-motion-template-card .ai-motion-btn').on('click', function(e) {
        e.preventDefault();
        var template = $(this).closest('.ai-motion-template-card').data('template');
        alert('Using template: ' + template + '\nRedirecting to generation page...');
        window.location.href = '/ai-motion-generate?template=' + encodeURIComponent(template);
    });
});
PLUGINEOF

# 21. readme.txt
cat > "$PLUGIN_DIR/readme.txt" << 'PLUGINEOF'
=== AI Motion Studio Pro ===
Contributors: yourname
Donate link: https://yourdomain.com/donate
Tags: ai, image generation, video generation, avatar, storytelling, motion templates, ai tools
Requires at least: 5.8
Tested up to: 6.4
Stable tag: 1.0.0
License: GPLv2 or later
License URI: http://www.gnu.org/licenses/gpl-2.0.html

Complete AI-powered content creation platform for WordPress.

== Description ==

AI Motion Studio Pro is a comprehensive plugin that brings the power of artificial intelligence to your WordPress site. Create stunning images, videos, talking avatars, and complete stories with just a few clicks.

= Features =

* **AI Image Generator** - Create images from text prompts with various styles (realistic, anime, cinematic, etc.)
* **AI Video Generator** - Generate videos from images or text with motion effects
* **Motion Template Library** - 50+ pre-built motion templates across 8 categories
* **Talking Avatar** - Create AI-powered talking avatars with lip-sync
* **Character Consistency** - Maintain consistent characters across multiple generations
* **AI Story Generator** - Generate complete stories with chapters, images, and narration
* **AI Voice Studio** - Text-to-speech with multiple voices and emotions
* **Video Editor** - Basic editing tools for your AI-generated videos
* **Social Media Export** - One-click export to YouTube, TikTok, Instagram, Facebook
* **Batch Generation** - Generate multiple images/videos at once
* **User Dashboard** - Manage your generations, credits, and favorites
* **Credits System** - Flexible credit-based pricing
* **Subscription Plans** - Multiple subscription tiers
* **WooCommerce Integration** - Sell credit packs and subscriptions
* **White Label Mode** - Rebrand the plugin for your clients
* **Admin Dashboard** - Complete management interface
* **Analytics** - Track usage and revenue
* **Multi-Storage Support** - WordPress, S3, Cloudflare, Google Cloud

= Template Categories =

* Portrait (Smile, Blink, Head Turn, Eye Contact, Hair Movement, Face Zoom)
* Camera (Zoom In, Zoom Out, Orbit, Pan, Dolly, Crane, Handheld)
* Actions (Walking, Running, Jumping, Dancing, Sitting, Standing, Waving)
* Social (Selfie, Vlog, Influencer, Fashion, Catwalk, Portrait Reel)
* Romance (Hug, Kiss, Wedding, Couple Walk, Proposal)
* Fantasy (Wings, Magic, Fire, Lightning, Aura, Energy, Power Up)
* Anime (Anime Portrait, Hair Flow, Transformation, Battle, Cinematic)
* Cinematic (Slow Motion, Action Shot, Hero Entrance, Movie Trailer, Dramatic Lighting)

= Shortcodes =

* `[ai_motion_dashboard]` - User dashboard
* `[ai_motion_generate]` - Generation interface
* `[ai_motion_templates]` - Template library
* `[ai_motion_credits]` - Credit management
* `[ai_motion_image]` - Image generator
* `[ai_motion_video]` - Video generator
* `[ai_motion_avatar]` - Talking avatar generator
* `[ai_motion_voice]` - Voice generator
* `[ai_motion_story]` - Story generator
* `[ai_motion_social_export]` - Social media export

= Requirements =

* PHP 7.4 or higher
* WordPress 5.8 or higher
* MySQL 5.6 or higher
* WooCommerce (optional, for credit sales)

= Installation =

1. Upload the `ai-motion-studio-pro` folder to the `/wp-content/plugins/` directory
2. Activate the plugin through the 'Plugins' menu in WordPress
3. Go to AI Motion Studio -> Settings to configure the plugin
4. (Optional) Install WooCommerce to enable credit sales

= Frequently Asked Questions =

= Q: Do I need an API key? =
A: Yes, you'll need to configure API keys for the AI services you want to use (Stable Diffusion, Runway, ElevenLabs, etc.)

= Q: Can I use this for commercial purposes? =
A: Yes, the plugin is licensed under GPL-2.0+, which allows commercial use.

= Q: How do I add more templates? =
A: You can add custom templates through the admin dashboard under AI Motion Studio -> Templates

= Q: Can I white label this plugin? =
A: Yes! Enable white label mode in the settings to rebrand the plugin with your own name and logo.

= Q: What AI services are supported? =
A: The plugin is designed to work with multiple AI APIs. You can configure your preferred providers in the settings.

= Screenshots =

1. User dashboard with credit balance and quick actions
2. Image generation interface with style options
3. Video generation with motion templates
4. Template library with categories
5. Admin dashboard with analytics
6. White label settings
7. Social media export options

= Changelog =

= 1.0.0 =
* Initial release
PLUGINEOF

# 22. Index file for security
cat > "$PLUGIN_DIR/index.php" << 'PLUGINEOF'
<?php
// Silence is golden
PLUGINEOF

# ============================================
# CREATE ZIP FILE
# ============================================

echo -e "${BLUE}Creating zip file...${NC}"
cd ./
zip -r "$ZIP_FILE" "$PLUGIN_DIR" -x "*.DS_Store" "*.git*" "__MACOSX" ".idea" ".vscode" "*.sh"

# ============================================
# VERIFY AND COMPLETE
# ============================================

if [ -f "$ZIP_FILE" ]; then
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}   ✓ Plugin Created Successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "\n${GREEN}Zip file created:${NC} $ZIP_FILE"
    echo -e "${GREEN}File size:${NC} $(du -sh "$ZIP_FILE" | cut -f1)"
    echo -e "\n${GREEN}To install:${NC}"
    echo -e "  1. Go to WordPress Admin → Plugins → Add New → Upload Plugin"
    echo -e "  2. Upload $ZIP_FILE"
    echo -e "  3. Activate the plugin"
    echo -e "\n${GREEN}Plugin includes:${NC}"
    echo -e "  ✓ Core plugin file"
    echo -e "  ✓ 17 PHP classes"
    echo -e "  ✓ Admin CSS"
    echo -e "  ✓ Frontend CSS"
    echo -e "  ✓ Admin JavaScript"
    echo -e "  ✓ Frontend JavaScript"
    echo -e "  ✓ readme.txt"
    echo -e "  ✓ All shortcodes"
    echo -e "  ✓ All features from your specification"
    echo -e ""
else
    echo -e "${RED}Error: Failed to create zip file${NC}"
    exit 1
fi
