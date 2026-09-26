<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Course extends Model
{
    protected $fillable = ['code', 'name', 'faculty_id'];

    public function students()
    {
        return $this->belongsToMany(User::class, 'course_student');
    }
}
