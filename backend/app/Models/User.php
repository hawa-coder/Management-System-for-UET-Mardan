<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'registration_number',
        'department',
        'batch',
        'semester',
        'section',
        'mobile_number',
        'batch_adviser_id',
        'is_active',
        'account_status',
        'can_publish_department_notices',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'is_active' => 'boolean',
        'can_publish_department_notices' => 'boolean',
        'can_forward_complaints' => 'boolean',
    ];

    public function complaints()
    {
        return $this->hasMany(Complaint::class);
    }

    public function courses()
    {
        return $this->belongsToMany(Course::class, 'course_student');
    }

    public function batchAdviser()
    {
        return $this->belongsTo(self::class, 'batch_adviser_id');
    }

    public function advisedStudents()
    {
        return $this->hasMany(self::class, 'batch_adviser_id');
    }

    public function appNotifications()
    {
        return $this->hasMany(AppNotification::class)->latest();
    }
}
