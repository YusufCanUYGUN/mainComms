// Dashboard charts and auto-refresh functionality

document.addEventListener('DOMContentLoaded', function() {
    // Auto-refresh data every 10 seconds
    setInterval(refreshData, 10000);
});

function refreshData() {
    // Refresh the page to get updated data
    // In a more advanced implementation, you would use AJAX
    // to fetch just the data and update the DOM
    // For now, we'll keep it simple
}

// Chart initialization for reactor EU output history
function initEUChart(canvasId, data) {
    const ctx = document.getElementById(canvasId);
    if (!ctx) return;

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: data.labels,
            datasets: [{
                label: 'EU/t Output',
                data: data.values,
                borderColor: '#e94560',
                backgroundColor: 'rgba(233, 69, 96, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: {
                        color: 'rgba(255, 255, 255, 0.1)'
                    },
                    ticks: {
                        color: '#888'
                    }
                },
                x: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        color: '#888'
                    }
                }
            }
        }
    });
}

// Chart for battery charge history
function initBatteryChart(canvasId, data) {
    const ctx = document.getElementById(canvasId);
    if (!ctx) return;

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: data.labels,
            datasets: [{
                label: 'Charge %',
                data: data.values,
                borderColor: '#28a745',
                backgroundColor: 'rgba(40, 167, 69, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    max: 100,
                    grid: {
                        color: 'rgba(255, 255, 255, 0.1)'
                    },
                    ticks: {
                        color: '#888',
                        callback: function(value) {
                            return value + '%';
                        }
                    }
                },
                x: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        color: '#888'
                    }
                }
            }
        }
    });
}

// Copy API key to clipboard
function copyApiKey(key) {
    navigator.clipboard.writeText(key).then(function() {
        alert('API key copied to clipboard!');
    }, function(err) {
        console.error('Could not copy text: ', err);
    });
}
